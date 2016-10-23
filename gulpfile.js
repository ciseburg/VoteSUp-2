var gulp        = require('gulp');
var bg          = require('gulp-bg');
var download    = require('gulp-download');
var zip         = require('gulp-zip');
var gzip        = require('gulp-gzip');
var gunzip      = require('gulp-gunzip');
var jshint      = require('gulp-jshint');
var gls         = require('gulp-live-server');
var install     = require('gulp-install');
var mocha       = require('gulp-mocha');
var tar         = require('gulp-tar');
var untar       = require('gulp-untar');
var gutil       = require('gulp-util');
var exec        = require('child_process').exec;
var del         = require('del');
var fs          = require('fs');
var runSequence = require('run-sequence');
var argv        = require('yargs').argv;


// default is 8000, which might be common
var ddbLocalPort = 8079;

// Delete the dist directory
gulp.task('clean', function (cb) {
  del(['cookbooks/VoteSUp/files/app/*', 'dist'], cb);
});

// Execute unit tests
gulp.task('test-unit', function () {
  return gulp.src('test-unit/*.js', {read: false})
             .pipe(mocha({reporter: 'spec'}));
});

// JSHint
gulp.task('lint-app', function() {
  return gulp.src(['.app.js', 'lib/*.js'])
             .pipe(jshint())
             .pipe(jshint.reporter('default', { verbose: true }))
             .pipe(jshint.reporter('fail'));
});
gulp.task('lint-chartController', function() {
  return gulp.src('public/chartController.js')
             .pipe(jshint({ 'globals': { Chart: true, voteSUpChartController: true }}))
             .pipe(jshint.reporter('default', { verbose: true }))
             .pipe(jshint.reporter('fail'));
});
gulp.task('lint', function(callback) {
  runSequence(
    ['lint-app', 'lint-chartController'],
    callback
  );
});

// Copy VoteSUp app to cookbooks/VoteSUp/files/default/app
gulp.task('cookbookfiles:app', function () {
  return gulp.src(['app.js', 'appspec.yml'] )
             .pipe(gulp.dest('cookbooks/VotesUp/files/default/app'));
});
gulp.task('cookbookfiles:lib', function () {
  return gulp.src(['lib/*.js'] )
             .pipe(gulp.dest('cookbooks/VotesUp/files/default/app/lib'));
});
gulp.task('cookbookfiles:public', function () {
  return gulp.src(['public/*'] )
             .pipe(gulp.dest('cookbooks/VotesUp/files/default/app/public'));
});
gulp.task('cookbookfiles:package', function () {
  return gulp.src(['package.json'])
             .pipe(gulp.dest('cookbooks/VotesUp/files/default/app'))
             .pipe(install({production: true}));
});

// Alias to run above tasks
gulp.task('copy-to-cookbooks', function(callback) {
  runSequence(
    [ 'cookbookfiles:app',
      'cookbookfiles:lib',
      'cookbookfiles:public',
      'cookbookfiles:package' ],
    callback
  );
});

// Copy cookbooks to dist/
gulp.task('dist:berks-vendor', function (cb) {
  exec('cd cookbooks/VoteSUp/ && berks vendor ../../dist', function (err, stdout, stderr) {
    gutil.log(stdout);
    gutil.log(stderr);
    cb(err);
  });
});

// Create tarball
gulp.task('dist:tar', function () {
  return gulp.src('dist/**/*')
             .pipe(tar('archive.tar'))
             .pipe(gzip())
             .pipe(gulp.dest('dist'));
});

// 'dist' ties together all dist tasks
gulp.task('dist', function(callback) {
  runSequence(
    'clean',
    'copy-to-cookbooks',
    'dist:berks-vendor',
    'dist:tar',
    callback
  );
});

// Execute business logic or functional tests
gulp.task('test-business', function () {
  if (process.env.hasOwnProperty('AUTOMATED_ACCEPTANCE_TEST')) {
    process.env.TARGET_URL = 'http://localhost:' + require(__dirname + '/dev-lib/targetPort.js');
  }
  return gulp.src('test-business/*.js', {read: false})
             .pipe(mocha({reporter: 'spec'}));
});

// run the node app
gulp.task('app:serve', function() {
  var server = gls.new('app.js');
  server.start();

  //use gulp.watch to trigger server actions(notify, start or stop)
  gulp.watch(['public/*'], function (file) {
    server.notify.apply(server, [file]);
  });
  gulp.watch(['app.js', 'lib/*.js'], function() {
    server.start.apply(server);
  });
});

// Support for DDB local - tasks to clean ddb dir, download and untar
gulp.task('localDynDB:clean', function (cb) {
  del(['localDynDB'], cb);
});

gulp.task('localDynDB:download', function() {
  return download('http://dynamodb-local.s3-website-us-west-2.amazonaws.com/dynamodb_local_latest.tar.gz')
                  .pipe(gulp.dest(__dirname + '/localDynDB/'));
});
gulp.task('localDynDB:untar', function () {
  return gulp.src(__dirname + '/localDynDB/dynamodb_local_latest.tar.gz')
             .pipe(gunzip())
             .pipe(untar())
             .pipe(gulp.dest('.'));
});

// Hacky way to run the localDynDB:download & localDynDB:untar only when we need to
gulp.task('localDynDB:download-wrapper', function(callback) {
  fs.stat(__dirname + '/localDynDB/DynamoDBLocal.jar', function(err) {
    if (err) {
      runSequence(
        'localDynDB:download',
        'localDynDB:untar',
        callback
      );
    } else {
      gutil.log(__dirname + '/localDynDB/DynamoDBLocal.jar exists. Skipping download.');
      callback();
    }
  });
});

gulp.task('localDynDB:serve', bg(
  'java', '-Djava.library.path=localDynDB/DynamoDBLocal_lib', '-jar', 'localDynDB/DynamoDBLocal.jar', '-dbPath', 'localDynDB/', '-sharedDb', '-port', ddbLocalPort
));

gulp.task('localDynDB', function(callback) {
  runSequence(
    'localDynDB:download-wrapper',
    'localDynDB:serve',
    callback
  );
});

// Default is to serve locally
gulp.task('serve', function(callback) {
  runSequence(
    'localDynDB',
    'app:serve',
    callback
  );
});

gulp.task('default', function(callback) {
  runSequence(
    'serve',
    callback
  );
});


gulp.task('package-site', ['lint-chartController'],function () {
  return gulp.src('public/**/*')
      .pipe(zip('site.zip'))
      .pipe(gulp.dest('dist'));
});

gulp.task('dist-app', function() {
  return gulp.src(['package.json','index.js','app.js','lib{,/*.js}'])
      .pipe(gulp.dest('dist/app/'))
      .pipe(install({production: true}));
});

gulp.task('package-app', ['lint-app','test-unit','dist-app'], function () {
  return gulp.src(['!dist/app/package.json','!dist/app/**/aws-sdk{,/**}', 'dist/app/**/*'])
      .pipe(zip('lambda.zip'))
      .pipe(gulp.dest('dist'));
});

gulp.task('package-swagger', function() {
  return gulp.src('swagger.json')
      .pipe(gulp.dest('dist/'));
});

gulp.task('package',['package-site','package-app','package-swagger'],  function() {
});


