pipeline {
    agent any

    environment {
        GIT_URL = "${GIT_URL}"
        GIT_BRANCH = "${GIT_BRANCH}"
        GIT_REPO_NAME = "ie-utils"
        PWD = pwd()
        CONFIG_FILE = "config.txt"
        CONFIG_PATH = "${PWD}/${CONFIG_FILE}"

        PRODUCT_UPDATE_SCRIPT_PATH = "product_update"
    }

    stages {
        stage('Download products packs from S3'){
            steps {
                sh """
                echo 'CONFIG_FILE=${CONFIG_FILE}' >> ${CONFIG_PATH}
                echo 'PWD=${PWD}' >> ${CONFIG_PATH}
                rm -rf wso2am-3.0.0.zip
                """

                withAWS(region:'us-east-1',credentials:'IE-AWS-CREDENTAILS') {
                    s3Download(file: 'wso2am-3.0.0.zip', bucket: 'wso2-base-product-packs', path: 'wso2am-3.0.0.zip', force: true)
                    s3Download(file: 'wso2am-analytics-3.0.0.zip', bucket: 'wso2-base-product-packs', path: 'wso2am-analytics-3.0.0.zip', force: true)
                    s3Download(file: 'wso2is-km-5.9.0.zip', bucket: 'wso2-base-product-packs', path: 'wso2is-km-5.9.0.zip', force: true)
                }
            }

        }

        stage('Clone ie-utils Repo') {
            steps {
                script {
                    echo pwd()
                    sh """
                        rm -rf ie-utils
                        git clone --branch ${GIT_BRANCH} ${GIT_URL}
                    """
                }
            }
        }

        stage('Add latest product updates'){
            steps{
            wrap([$class: 'MaskPasswordsBuildWrapper']) {
                withCredentials([string(credentialsId: 'WUM_USERNAME', variable: 'WUM_USER'),
                                 string(credentialsId: 'WUM_PASSWORD', variable: 'WUM_PASS')
                ])
                {
                sh """
                    cd "${GIT_REPO_NAME}/${PRODUCT_UPDATE_SCRIPT_PATH}"
                    echo "Setting up the environment ..."
                    sudo bash setup.sh
                    echo "Updating WSO2 products ..."
                    bash daily_update.sh
                """
                }

            }
            }
        }


        stage('Generate Ansible Installer') {
            steps {
                script {
                    echo pwd()
                    sh """
                        cd ie-utils/installers/ansible
                        sh create-zip.sh
                    """
                }
            }
        }
        
        stage('Generate Puppet Installer'){
            steps {
                script {
                    echo pwd()
                    sh """
                        cd ie-utils/installers/puppet
                        sh create-zip.sh
                    """
                }
            }
        }
    }
}
