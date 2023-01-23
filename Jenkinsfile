pipeline{
   


    agent any
    environment{
        AWS_DEFAULT_REGION="eu-west-3"
        SKIP="N"
        TERRADESTROY="Y"
        FIRST_DEPLOY="Y"
        STATE_BUCKET="cley-tfstate-bucket"
        ANSIBLE_BUCKET_NAME="cley-ansible-bucket"
    }




    stages{

        stage("Create Terraform State Bucket"){
            when{
                environment name:'FIRST_DEPLOY',value:'Y'
                environment name:'TERRADESTROY',value:'N'
                environment name:'SKIP',value:'N'
            }
            steps{
                    sh'''
                    aws s3 mb s3://${STATE_BUCKET}'''
            }
        }

        stage("Deploy Ansible Infra"){
            when{
                    environment name:'TERRADESTROY',value:'N'
                    environment name:'SKIP',value:'N'
                }
             stages{
                        stage('Validate Ansible Infra'){
                            steps{
                                    sh '''
                                    cd ansible_infra
                                    terraform init
                                    terraform validate'''
                            }
                        }
                        stage('Deploy Ansible Infra'){
                            steps{
                                    sh '''
                                    cd ansible_infra
                                    terraform plan -out outfile
                                    terraform apply outfile'''
                            }
                        }
                    }
        }


        stage("Deploy Networking"){
            when{
                    environment name:'TERRADESTROY',value:'N'
                    environment name:'SKIP',value:'N'
                }
             stages{
                        stage('Validate n/w Infra'){
                            steps{
                                    sh '''
                                    cd networking
                                    terraform init
                                    terraform validate'''
                            }
                        }
                        stage('Deploy n/w Infra'){
                            steps{
                                    sh '''
                                    cd networking
                                    terraform plan -out outfile
                                    terraform apply outfile'''
                            }
                        }
                    }
        }

        stage("Deploy Controlplane"){
             when{
                    environment name:'TERRADESTROY',value:'N'
                    environment name:'SKIP',value:'N'
                }
            stages{
                stage("deploy instance"){
                    when{
                    environment name:'SKIP',value:'N'
                }
                    stages{
                        stage('Validate inst Infra'){
                            steps{
                                    sh '''
                                    cd instances
                                    terraform init
                                    terraform validate'''
                            }
                        }
                        stage('Deploy inst Infra'){
                            steps{
                                    sh '''
                                    cd instances
                                    terraform plan -out outfile
                                    terraform apply outfile'''
                            }
                        }
                        stage('Prepare inv file'){
                            when{
                                environment name:'SKIP',value:'N'
                            }
                            steps{
                                    script {
                                            sh """
                                            ansible --version
                                            cd ansible_infra
                                            cd ansible_playbooks
                                            env
                                            ansible-playbook identify_controlplane.yml -i inv 
                                            cat inv
                                            """
                                            }
                            }
                        }
                        stage ("Wait 60s to ensure boostrap is ready") {
                            steps{ 
                                echo 'Waiting 60 seconds to ensure bootstrap is running'
                                sleep 60 // seconds
                            }
                        }
                    }
                }
                stage("bootstrap instance"){
                    when{
                                environment name:'SKIP',value:'N'
                            }
                    steps{
                            script {
                                        sh """
                                        cd ansible_infra
                                       cd ansible_role
                                        aws s3 cp s3://${ANSIBLE_BUCKET_NAME}/inv inv
                                        ls -a
                                        pwd
                                        ansible-playbook main.yml -i inv                                    
                                        """
                                    }
                    }
                }

                stage("test kubectl"){
                    steps{
                            script {
                                        sh """
                                        cd ansible_infra
                                        cd ansible_playbooks
                                        aws s3 cp s3://${ANSIBLE_BUCKET_NAME}/inv inv
                                        ansible-playbook testkubectl.yml -i inv                                     
                                        """
                                    }
                    }
                }
            }
        }


        stage("Launch Nodes"){
            when{
                    environment name:'TERRADESTROY',value:'N'
                    environment name:'SKIP',value:'N'
                }
            stages{
                stage("deploy asg"){
                     when{
                                environment name:'SKIP',value:'N'
                            }
                    stages{
                        stage('Validate asg Infra'){
                            steps{
                                    sh '''
                                    cd node_asg
                                    terraform init
                                    terraform validate'''
                            }
                        }
                        stage('Deploy asg Infra'){
                            steps{
                                    sh '''
                                    cd node_asg
                                    terraform plan -out outfile
                                    terraform apply outfile'''
                            }
                        }
                    }
                }

                stage("generate join token"){
                     when{
                                environment name:'SKIP',value:'N'
                            }
                    steps{
                            script {
                                        sh """
                                        cd ansible_infra
                                        cd ansible_playbooks
                                       aws s3 cp s3://${ANSIBLE_BUCKET_NAME}/inv inv
                                        ansible-playbook main_kubeadm_token.yml -i inv                        
                                       """
                                    }
                    }
                }

                stage("update node inventory file"){
                     when{
                                environment name:'SKIP',value:'N'
                            }
                    steps{
                            script {
                                        sh """
                                        cd ansible_infra
                                        cd ansible_playbooks
                                        aws s3 cp s3://${ANSIBLE_BUCKET_NAME}/inv inv
                                        ansible-playbook identify_nodes.yml -i inv  
                                        """
                                    }
                    }
                }

                stage ("Wait 60s to ensure instances are ready") {
                    steps{ 
                        echo 'Waiting 60 seconds to ensure instances are running'
                        sleep 60 // seconds
                    }
                }

                stage("bootstrap instance"){
                    when{
                                environment name:'SKIP',value:'N'
                            }
                    steps{
                            script {
                                        sh """
                                        cd ansible_infra
                                        cd ansible_role
                                        aws s3 cp s3://${ANSIBLE_BUCKET_NAME}/nodeinv nodeinv
                                        ls -a
                                        pwd
                                        ansible-playbook kubenode.yml -i nodeinv      
                                        cd ..
                                        cd ansible_playbooks
                                        rm -f nodeinv
                                        aws s3 cp s3://${ANSIBLE_BUCKET_NAME}/nodeinv nodeinv
                                        ansible-playbook bootstrap_node.yml -i nodeinv  
                                        ls -a
                                       """
                                    }
                    }
                }

                stage("test kubectl for nodes"){
                    steps{
                            script {
                                        sh """
                                        cd ansible_infra
                                        cd ansible_playbooks
                                        aws s3 cp s3://${ANSIBLE_BUCKET_NAME}/inv inv
                                        ansible-playbook testkubectl.yml -i inv                                   
                                        """
                                    }
        
                    }
                }
            }

        }       

        stage("Run Destroy"){
            when{
                environment name:'TERRADESTROY',value:'Y'
            }
            stages{
                stage("Destroy Ansible Infra"){
                    steps{
                            sh '''
                                cd ansible_infra
                                terraform init
                                terraform destroy -auto-approve
                                '''
                    }
                }

                stage("Destroy instance Infra"){
                    steps{    
                            sh '''
                                cd instances
                                terraform init
                                terraform destroy -auto-approve
                                '''
                    }
                }

                stage("Destroy node Infra"){
                    steps{
                            sh '''
                                cd node_asg
                                terraform init
                                terraform destroy -auto-approve
                                '''
                    }
                }

                stage("Destroy n/w Infra"){
                    steps{
                            sh '''
                                cd networking
                                terraform init
                                terraform destroy -auto-approve
                                '''        
                    }
                }

                

                

                //next stage

                stage("Destroy state bucket"){
                    steps{        
                            sh '''
                                aws s3 rb s3://${STATE_BUCKET} --force
                                '''      
                    }
                }
            }
        }

        //new stage from here

    }

    post { 
        always { 
            cleanWs()
        }
    }

}
