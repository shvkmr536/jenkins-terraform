pipeline {
  agent any
  environment {
    TERRAFORM_HOME = tool 'myTerraform'
    EXAMPLE_KEY = credentials('aws-cred') // Secret value is 'sec%ret'
  }
  stages{
    stage('Check Terraform path & Version'){
      steps{
      sh 'echo $TERRAFORM_HOME'
      sh 'echo ${TERRAFORM_HOME}/terraform --version'
    }
  }
  stage('Terraform init'){
    steps{
    sh "${TERRAFORM_HOME}/terraform init -input=false"
  }
}
  stage('Terraform Plan'){
    steps{
      sh "${TERRAFORM_HOME}/terraform plan -out tfplan"
    }
  }
  stage('Terraform Apply'){
    steps{
      sh "${TERRAFORM_HOME}/terraform apply -refresh=false tfplan"
    }
  }
   stage('Terraform destroy'){
     steps{
        sh "${TERRAFORM_HOME}/terraform destroy -auto-approve"
      }
    }
}
}
    
