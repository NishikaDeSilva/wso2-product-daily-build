#!/bin/bash
cat acsii_art_ansible.txt 
params_file="ansible-params.json"

function log_info(){
    msg=$1
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]: [INFO] ${msg}"
}

platforms=$(jq -r '.platforms[].name' ${params_file} )

for platform in $(printf '%s\n' "${platforms[@]}")
do 
    log_info "Creating ansible resources for ${platform}"    

    parent_repo=$(jq -r '.platforms[] | select( .name == '\"${platform}\"') | .git_repo.parent' ${params_file} )
    repo=$(jq -r '.platforms[] | select( .name == '\"${platform}\"') | .git_repo.name' ${params_file} )
    branch=$(jq -r '.platforms[] | select( .name == '\"${platform}\"') | .git_repo.branch' ${params_file} )

    log_info "Cloning repository ${parent_repo}/${repo}"
    git clone "https://github.com/${parent_repo}/${repo}" && git checkout ${branch} 

    # add dependencies
    log_info "Adding JDK"
    curl -L $(jq -r '.common.jdk_download_link' ${params_file}) --create-dirs -o ${repo}/files/lib/jdk-distribution.tar.gz

    log_info "Adding JDBC Driver"
    mkdir -p trash dir && wget -q $(jq -r '.common.jdbc_download_link' ${params_file}) -P trash/
    unzip -qd dir/ trash/*
    jar_file_location=$(find dir -name '*bin.jar') && mv ${jar_file_location} ${repo}/files/lib/db-connector-java.jar

    rm -r trash dir

    #add products to files/packs/
    products=$(jq -r '.platforms[] | select( .name == '\"${platform}\"') | .products' ${params_file})

    for row in $(echo "${products}" | jq -r '.[] | @base64')
    do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
        }

    product_name=$(_jq '.name')
    product_version=$(_jq '.version')
    product_zip="${product_name}-${product_version}.zip"

    log_info "Adding ${product_name}-${product_version}.zip"
    mkdir -p ${repo}/files/packs && cp ~/.wum3/products/${product_name}/${product_version}/${product_zip} ${repo}/files/packs/

    done

    log_info "Creating ansible installer zip"
    zip -qr ${repo}.zip ${repo}/* && rm -rf ${repo}

    log_info "Successfully created ansible installer for ${platform}"
done