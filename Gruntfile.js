module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    peg: {
      datascript: {
        src: 'grammar/datascript.pegjs',
        dest: 'lib/parser.js'
      }
    }
  });

  grunt.loadNpmTasks('grunt-peg');
  grunt.registerTask('default', 'peg');
};
