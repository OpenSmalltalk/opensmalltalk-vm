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
    withEnv(["PHARO_CI_TESTING_ENVIRONMENT=true"]) {    
      return sh(c)
    }
}

def buildGTKBundle(){
	node("unix"){
		cleanWs()
		stage("build-GTK-bundle"){

			def commitHash = checkout(scm).GIT_COMMIT

			unstash name: "packages-windows-CoInterpreterWithQueueFFI"
			def shortGitHash = commitHash.substring(0,8)
			def gtkBundleName = "PharoVM-8.1.0-GTK-${shortGitHash}-win64-bin.zip"

			dir("build"){
				shell "wget http://files.pharo.org/vm/pharo-spur64/win/third-party/Gtk3.zip"
				shell "unzip Gtk3.zip -d ./bundleGTK"
				shell "unzip -n build/packages/PharoVM-*-win64-bin.zip -d ./bundleGTK"

				dir("bundleGTK"){
					shell "zip -r -9 ../${gtkBundleName} *"
				}
			
				stash includes: "${gtkBundleName}", name: "packages-windows-gtkBundle"
				archiveArtifacts artifacts: "${gtkBundleName}"
				
				if(!isPullRequest() && env.BRANCH_NAME == 'headless'){
					sshagent (credentials: ['b5248b59-a193-4457-8459-e28e9eb29ed7']) {
						sh "scp -o StrictHostKeyChecking=no \
						${gtkBundleName} \
						pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/win/${gtkBundleName}"

						sh "scp -o StrictHostKeyChecking=no \
						${gtkBundleName} \
						pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/win/latest-win64-GTK.zip"
					}
				}
			}
		}
	}
}

def runBuild(platform, configuration){
	cleanWs()
	

    stage("Checkout-${platform}"){
      dir('repository') {
          checkout scm
      }
    }


	stage("Build-${platform}-${configuration}"){
    if(isWindows()){
      runInCygwin "mkdir build"
      runInCygwin "cd build && cmake -DFLAVOUR=${configuration} ../repository"
      runInCygwin "cd build && make install"
      runInCygwin "cd build && make package"
    }else{
      cmakeBuild generator: "Unix Makefiles", cmakeArgs: "-DFLAVOUR=${configuration}", sourceDir: "repository", buildDir: "build", installation: "InSearchPath"
      dir("build"){
        shell "make install"
        shell "make package"
      }
    }
		stash excludes: '_CPack_Packages', includes: 'build/build/packages/*', name: "packages-${platform}-${configuration}"
		archiveArtifacts artifacts: 'build/build/packages/*', excludes: '_CPack_Packages'
	}
}

def runTests(platform, configuration, packages, withWorker){
	cleanWs()

	def stageName = withWorker ? "Tests-${platform}-${configuration}-worker" : "Tests-${platform}-${configuration}"

	stage(stageName){
		
		def vmDir = ''
		
		if(platform == 'osx'){
			vmDir = 'mac'
		}else{
			if(platform == 'unix')
				vmDir = 'linux'
			else
				vmDir = 'win'
		}

    	unstash name: "packages-${platform}-${configuration}"

    	shell "mkdir runTests"
    	dir("runTests"){
          shell "wget -O - get.pharo.org/64/90 | bash "
          shell "echo 90 > pharo.version"
          
          if(isWindows()){
            runInCygwin "cd runTests && unzip ../build/build/packages/PharoVM-*-${vmDir}64-bin.zip -d ."
			if(withWorker){
	            runInCygwin "PHARO_CI_TESTING_ENVIRONMENT=true cd runTests && ./PharoConsole.exe  --logLevel=4 --worker Pharo.image test --junit-xml-output --stage-name=win64-${configuration}-worker '${packages}'"
			}else{
				runInCygwin "PHARO_CI_TESTING_ENVIRONMENT=true cd runTests && ./PharoConsole.exe  --logLevel=4 Pharo.image test --junit-xml-output --stage-name=win64-${configuration} '${packages}'"
			}
    	  }else{
            shell "unzip ../build/build/packages/PharoVM-*-${vmDir}64-bin.zip -d ."

            if(platform == 'osx'){
				if(withWorker){
					shell "PHARO_CI_TESTING_ENVIRONMENT=true ./Pharo.app/Contents/MacOS/Pharo --logLevel=4 --worker Pharo.image test --junit-xml-output --stage-name=osx64-${configuration}-worker '${packages}'"
				} else {
	                shell "PHARO_CI_TESTING_ENVIRONMENT=true ./Pharo.app/Contents/MacOS/Pharo --logLevel=4 Pharo.image test --junit-xml-output --stage-name=osx64-${configuration} '${packages}'"
				}
    		}			
            if(platform == 'unix'){
				if(withWorker){
	                shell "PHARO_CI_TESTING_ENVIRONMENT=true ./pharo --logLevel=4 --worker Pharo.image test --junit-xml-output --stage-name=unix64-${configuration}-worker '${packages}'" 
				}else{
	                shell "PHARO_CI_TESTING_ENVIRONMENT=true ./pharo --logLevel=4 Pharo.image test --junit-xml-output --stage-name=unix64-${configuration} '${packages}'" 
				}
            }
    	  }
    		junit allowEmptyResults: true, testResults: "*.xml"
    	}
				
		archiveArtifacts artifacts: 'runTests/*.xml', excludes: '_CPack_Packages'
	}
}

def upload(platform, configuration, vmDir) {

	cleanWs()

	unstash name: "packages-${platform}-${configuration}"

	def expandedBinaryFileName = sh(returnStdout: true, script: "ls build/build/packages/PharoVM-*-${vmDir}64-bin.zip").trim()
	def expandedHeadersFileName = sh(returnStdout: true, script: "ls build/build/packages/PharoVM-*-${vmDir}64-include.zip").trim()

	sshagent (credentials: ['b5248b59-a193-4457-8459-e28e9eb29ed7']) {
		sh "scp -o StrictHostKeyChecking=no \
		${expandedBinaryFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/${vmDir}"
		sh "scp -o StrictHostKeyChecking=no \
		${expandedHeadersFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/${vmDir}/include"

		sh "scp -o StrictHostKeyChecking=no \
		${expandedBinaryFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/${vmDir}/latest.zip"
		sh "scp -o StrictHostKeyChecking=no \
		${expandedHeadersFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/${vmDir}/include/latest.zip"
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
			
			upload('osx', "CoInterpreterWithQueueFFI", 'mac')
			upload('unix', "CoInterpreterWithQueueFFI",'linux')
			upload('windows', "CoInterpreterWithQueueFFI", 'win')
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
					runBuild(platform, "CoInterpreterWithQueueFFI")
				}
			}
		}
		
		tests[platform] = {
			node(platform){
				timeout(45){
					runTests(platform, "CoInterpreterWithQueueFFI", ".*", false)
				}
				timeout(45){
					runTests(platform, "CoInterpreterWithQueueFFI", ".*", true)
				}				
			}
		}
	}
/*  
  builders["StackVM"] = {
    node('osx'){
      timeout(30){
        runBuild('osx', "StackVM")
      }
    }
  }
  tests["StackVM"] = {
    node('osx'){
      timeout(40){
        runTests('osx', "StackVM", "Kernel.*")
      }
    }
  }
*/    
	parallel builders
	
	uploadPackages()

	buildGTKBundle()

	parallel tests

} catch (e) {
  throw e
}
