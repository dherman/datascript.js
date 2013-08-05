var parse = require('../lib/parser').parse;
var fs = require('fs');

function sync(f) {
    return function(test) {
        try {
            f(test);
        } finally {
            test.done();
        }
    };
}

exports.testStruct = sync(function(test) {
    test.doesNotThrow(function() {
        parse("Foo { };");
    });
});

exports.testConsts = sync(function(test) {
    test.doesNotThrow(function() {
        parse("const uint16 C = 0x0; const uint16 D = 0x0; Foo { };");
    });
});

exports.testEnum = sync(function(test) {
    test.doesNotThrow(function() {
        parse("enum uint8 M{A,B,C} stuff;");
    });
});

exports.testBitmask1 = sync(function(test) {
    test.doesNotThrow(function() {
        parse("bitmask uint16 ClassFlags { ACC_PUBLIC, ACC_FINAL, ACC_ABSTRACT, ACC_INTERFACE, ACC_SUPER } access_flags;");
    });
});

exports.testBitmask2 = sync(function(test) {
    test.doesNotThrow(function() {
        parse("bitmask uint16 M{A,B,C} stuff;");
    });
});

exports.testKeywordsIdentifiersDisjoint = sync(function(test) {
    test.doesNotThrow(function() {
        parse("ClassFile { {\n uint16 ifidx : clazz(ifidx); }\n interfaces[interfaces_count];\n };");
    });
});

exports.testClassfile = sync(function(test) {
    test.doesNotThrow(function() {
        parse(fs.readFileSync(__dirname + "/classfile.ds", 'utf-8'));
    });
});

// test.throws(function() { ... })
// test.equal(actual, expected)
