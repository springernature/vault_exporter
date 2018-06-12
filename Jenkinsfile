pipeline {
  agent {
    node {
      label 'flint'
      customWorkspace "/var/lib/jenkins/go/src/github.com/grapeshot/vault_exporter"
    }
  }
  environment {
    GOPATH = "$HOME/go:$WORKSPACE/go"
  }

  stages {

    stage ('Prologue') {
      steps {
        bitbucketStatusNotify ( buildState: 'INPROGRESS' )
        sh 'make clean'
      }
    }

    stage('Pre Test') {
      steps {
        echo 'Pulling Dependencies'

        sh 'go version'
        sh 'go get -u github.com/golang/dep/cmd/dep'
        sh 'go get -u github.com/golang/lint/golint'
        sh 'go get -u gopkg.in/alecthomas/gometalinter.v2'
        sh 'gometalinter.v2 --install'
      }
    }

    stage('Test') {
      steps {
        sh 'make format'
        sh 'make lint'
      }
    }

    stage('Build') {
      steps {
        sh 'make build'
        sh 'make build-image'
      }
    }

    stage('Push') {
      steps {
        sh 'make ecr-push'
      }
    }

    stage('Release') {
      steps {
        script {
          if (BRANCH_NAME == 'master') {
            try {
              timeout(time: 15, unit: 'SECONDS') {
                input(message: 'Would you like to release this code?')
              }
              withCredentials([usernameColonPassword(credentialsId: "jenkins-docker-hub", variable: 'HUB_CREDENTIALS')]) {
                sh 'make hub-push'
                sh 'make release'
              }
            } catch (err) {
              def user = err.getCauses()[0].getUser()
              if ('SYSTEM' == user.toString()) {
                currentBuild.result = "SUCCESS"
              }
            }
          }
        }
      }
    }
  }

  post {
    aborted {
      // should only happen on input timeout, which we don't regard as a failure
      bitbucketStatusNotify(buildState: 'SUCCESSFUL' )
    }

    success {
      bitbucketStatusNotify(buildState: 'SUCCESSFUL' )
    }

    failure {
      bitbucketStatusNotify(buildState: 'FAILED' )
      slackSend  message: 'vault_exporter build error at ' + env.BUILD_URL + ': ' + err.getMessage()
    }
  }
}
