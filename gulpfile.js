var gulp = require('gulp');
var gutil = require('gulp-util');
var rename = require('gulp-rename');
var uglify = require('gulp-uglify');
var browserify = require('gulp-browserify');
var optimizeBrowserify = require('gulp-optimizebrowserify');
var plumber = require('gulp-plumber');
var sequence = require('run-sequence');


var paths = {
	js: {
		src: 'src/index.coffee',
		target: 'miwo-data.js',
		distDir: './dist/js/'
	},
	watch: {
		coffee: ['src/**/*.coffee']
	}
};


var pipes = {
	createPlumber: function() {
		return plumber(function(error) {
			gutil.log(gutil.colors.red(error.message));
			gutil.beep();
			this.emit('end');
		});
	}
};



gulp.task('default', ['build']);

gulp.task("watch", function() {
	gulp.start('build');
	gulp.watch(paths.watch.coffee, ['compile-js']);
});

gulp.task('build', function(cb) {
	sequence(['compile-js'], cb);
});

gulp.task('dist', function(cb) {
	sequence('build', ['minify-js'], cb);
});



gulp.task('compile-js', function() {
	return gulp.src(paths.js.src, { read: false })
		.pipe(pipes.createPlumber())
		.pipe(browserify({transform: ['caching-coffeeify'], extensions: ['.coffee']}))
		.pipe(rename(paths.js.target))
		.pipe(gulp.dest(paths.js.distDir));
});

gulp.task('minify-js', function() {
	return gulp.src(paths.js.distDir+paths.js.target)
		.pipe(optimizeBrowserify())
		.pipe(uglify())
		.pipe(rename({suffix:'.min'}))
		.pipe(gulp.dest(paths.js.distDir));
});