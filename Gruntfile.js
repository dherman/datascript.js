module.exports = function(grunt) {
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        peg: {
            datascript: {
                src: 'grammar/datascript.pegjs',
                dest: 'lib/parser.js'
            }
        },
        nodeunit: {
            all: ['test/*_test.js']
        }
    });

    grunt.loadNpmTasks('grunt-contrib-nodeunit');
    grunt.loadNpmTasks('grunt-peg');
    grunt.registerTask('default', 'peg');
    grunt.registerTask('test', 'nodeunit');
};
