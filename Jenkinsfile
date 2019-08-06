def isWindows(){
  //If NODE_LABELS environment variable is null, we assume we are on master unix machine
  if (env.NODE_LABELS == null) {
    return false
  }
    return env.NODE_LABELS.toLowerCase().contains('windows')
}

def shell(params){
    if(isWindows()) bat(params) 
    else sh(params)
}

def runInCygwin(command){
    def c = """#!c:\\cygwin64\\bin\\bash --login
    cd `cygpath \"$WORKSPACE\"`
    set -ex
    ${command}
    """
    
    echo("Executing: ${c}")
    return sh(c)
}


def runBuild(platform){
	cleanWs()
	

    stage("Checkout-${platform}"){
        checkout scm
    }


	stage("Build-${platform}"){
    	if(isWindows()){
    	    runInCygwin "cmake . -DWIN=1"
    	    runInCygwin "make install"
    	    runInCygwin "make package"
    	}else{
    		cmakeBuild generator: 'Unix Makefiles', installation: 'InSearchPath'
    		shell "make install"
			shell "make package"			
    	}
		
		stash excludes: '_CPack_Packages', includes: 'build/packages/*', name: "packages-${platform}"
		archiveArtifacts artifacts: 'build/packages/*', excludes: '_CPack_Packages'
	}
}

def runTests(platform){
	cleanWs()

	stage("Tests-${platform}"){
		
		def vmDir = ''
		
		if(platform == 'osx'){
			vmDir = 'mac'
		}else{
			if(platform == 'unix')
				vmDir = 'linux'
			else
				vmDir = 'win'
		}

		unstash name: "packages-${platform}"
    
    environment { 
      PHARO_CI_TESTING_ENVIRONMENT = 'true'
    }

		shell "mkdir runTests"
		dir("runTests"){
      shell "wget -O - get.pharo.org/64/80 | bash "
      runInCygwin "unzip build/packages/PharoVM-*-${vmDir}64.zip -d ."
      if(isWindows()){
			  runInCygwin "PHARO_CI_TESTING_ENVIRONMENT=true cd runTests; Pharo.exe Pharo.image test --junit-xml-output --stage-name=win64 .*"
		   }else{          
        if(platform == 'osx'){
          shell "PHARO_CI_TESTING_ENVIRONMENT=true ./Pharo.app/Contents/MacOS/Pharo Pharo.image test --junit-xml-output --stage-name=osx64 '.*'"
				}			
        if(platform == 'unix'){
          shell "PHARO_CI_TESTING_ENVIRONMENT=true ./pharo Pharo.image test --junit-xml-output --stage-name=unix64 '.*'" 
        }
		  }
		  junit allowEmptyResults: true, testResults: "*.xml"
	  }
				
		stash excludes: '_CPack_Packages', includes: 'build/packages/*', name: "packages-${platform}"
		archiveArtifacts artifacts: 'runTests/*.xml', excludes: '_CPack_Packages'
	}
}

def upload(platform, vmDir) {

	unstash name: "packages-${platform}"

	def expandedFileName = sh(returnStdout: true, script: "ls build/packages/PharoVM-*-${vmDir}64.zip").trim()

	sshagent (credentials: ['b5248b59-a193-4457-8459-e28e9eb29ed7']) {
		sh "scp -o StrictHostKeyChecking=no \
		${expandedFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/${vmDir}"

		sh "scp -o StrictHostKeyChecking=no \
		${expandedFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/${vmDir}/latest.zip"
	}
}

def isPullRequest() {
  return env.CHANGE_ID != null
}

def uploadPackages(){
	node('unix'){
		stage('Upload'){
			if (isPullRequest()) {
				//Only upload files if not in a PR (i.e., CHANGE_ID not empty)
				echo "[DO NO UPLOAD] In PR " + (env.CHANGE_ID?.trim())
				return;
			}
			
			if(env.BRANCH_NAME != 'headless'){
				echo "[DO NO UPLOAD] In branch different that 'headless': ${env.BRANCH_NAME}";
				return;
			}
			
			upload('osx', 'mac')
			upload('unix', 'linux')
			upload('windows', 'win')
		}
	}
}

try{
    properties([disableConcurrentBuilds()])

    def platforms = ['unix', 'osx', 'windows']
	def builders = [:]
	def tests = [:]

	for (platf in platforms) {
        // Need to bind the label variable before the closure - can't do 'for (label in labels)'
        def platform = platf
		
		builders[platform] = {
			node(platform){
				timeout(30){
					runBuild(platform)
				}
			}
		}
		
		tests[platform] = {
			node(platform){
				timeout(30){
					runTests(platform)
				}
			}
		}
	}
	
	parallel builders
	
	uploadPackages()

	parallel tests

} catch (e) {
  throw e
}
