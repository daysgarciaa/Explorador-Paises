// Pegar en Jenkins → New Item → Pipeline → "Pipeline script"
// Requisitos: job freestyle llamado "BuildAppJob" que ejecuta ./build.sh en el workspace clonado.

node {
    stage('Preparation') {
        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
            sh 'docker stop samplerunning || true'
            sh 'docker rm samplerunning || true'
        }
    }
    stage('Build') {
        build job: 'BuildAppJob', wait: true, propagate: true
    }
}
