 node ('osx') {
  stage 'Checkout'
  checkout scm
  echo env.BRANCH_NAME
  stage 'Setup'
  env.PATH = "/usr/local/bin/:${env.PATH}"
  env.LANG = "en_US.UTF-8"
  env.LC_ALL = "en_US.UTF-8"
  sh 'chmod +x External/gems/bin/*'
  sh 'security unlock-keychain -p vagrant'
  sh '/usr/local/bin/pod spec lint SPHWNetworking.podspec --allow-warnings'
  if(env.BRANCH_NAME == "release"){
    sh 'pod trunk push SPHWNetworking.podspec  --allow-warnings'
  }
 }
