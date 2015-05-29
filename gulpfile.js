var gulp = require('gulp');
var gutil = require('gulp-util');
var rename = require('gulp-rename');
var uglify = require('gulp-uglify');
var browserify = require('gulp-browserify');
var optimizeBrowserify = require('gulp-optimize-browserify');


var paths = {
	watch: {
		coffee: ['src/**/*.coffee']
	}
};


var pipes = {
	createBrowserify: function(options) {
		var pipe = browserify(options);
		pipe.on('error', function(err) {
			gutil.log(err);
			gutil.beep();
		});
		return pipe;
	}
};



gulp.task('default', ['build', 'watch']);

gulp.task('build', ['compile-js']);

gulp.task('dist', ['compile-js', 'minify-js']);

gulp.task("watch", function() {
	gulp.watch(paths.watch.coffee, ['compile-js']);
});


gulp.task('compile-js', function() {
	return gulp.src('./src/index.coffee', { read: false })
		.pipe(pipes.createBrowserify({transform: ['caching-coffeeify'], extensions: ['.coffee'], debug:true}))
		.pipe(rename('miwo-data.js'))
		.pipe(gulp.dest('./dist/js/'));
});

gulp.task('minify-js', function() {
	return gulp.src('src/index.coffee', { read: false })
		.pipe(pipes.createBrowserify({transform: ['caching-coffeeify'], extensions: ['.coffee']}))
		.pipe(optimizeBrowserify())
		.pipe(uglify())
		.pipe(rename('miwo-data.min.js'))
		.pipe(gulp.dest('./dist/js/'));
});