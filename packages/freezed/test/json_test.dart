// @dart=2.9

// ignore_for_file: prefer_const_constructors, omit_local_variable_types
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import 'common.dart';
import 'integration/json.dart';

Future<void> main() async {
  final jsonFile = await resolveSources(
    {'freezed|test/integration/json.dart': useAssetReader},
    (r) => r.libraries
        .firstWhere((element) => element.source.toString().contains('json')),
  );

  test('can have a custom fromJson', () {
    expect(
      Regression280.fromJson(<String, String>{'foo': 'value'}),
      Regression280('value'),
    );
    expect(
      Regression280n2.fromJson('hello'),
      Regression280n2('hello'),
    );

    expect(
      jsonFile.topLevelElements.any((e) => e.name == r'_$Regresssion280'),
      isFalse,
    );
    expect(
      jsonFile.topLevelElements.any((e) => e.name == r'_$Regresssion280n2'),
      isFalse,
    );
  });

  test('custom fromJson + json_serializable', () {
    expect(
      CustomJson.fromJson(<String, dynamic>{'key': 'value'}),
      CustomJson('value'),
    );
  });

  group('Freezed.unionKey', () {
    test('fromJson', () {
      expect(
        CustomKey.fromJson(<String, dynamic>{'type': 'first', 'a': 42}),
        CustomKey.first(42),
      );

      expect(
        CustomKey.fromJson(<String, dynamic>{'type': 'second', 'a': 21}),
        CustomKey.second(21),
      );

      expect(
        RawCustomKey.fromJson(<String, dynamic>{'\$type': 'first', 'a': 42}),
        RawCustomKey.first(42),
      );

      expect(
        FancyCustomKey.fromJson(<String, dynamic>{'ty"\'pe': 'first', 'a': 42}),
        FancyCustomKey.first(42),
      );
    });

    test('toJson', () {
      expect(
        CustomKey.first(42).toJson(),
        <String, dynamic>{'type': 'first', 'a': 42},
      );

      expect(
        CustomKey.second(21).toJson(),
        <String, dynamic>{'type': 'second', 'a': 21},
      );

      expect(
        RawCustomKey.first(42).toJson(),
        <String, dynamic>{'\$type': 'first', 'a': 42},
      );

      expect(
        FancyCustomKey.first(42).toJson(),
        <String, dynamic>{'ty"\'pe': 'first', 'a': 42},
      );
    });
  });

  test('class decorators are applied on the generated class', () {
    expect(
      ClassDecorator('Complex name').toJson(),
      {
        'complex_name': 'Complex name',
      },
    );
  });

  test('@Default implies a @JsonKey', () {
    final value = DefaultValue();
    expect(
      value.toJson(),
      {'value': 42},
    );

    expect(
      DefaultValue.fromJson(<String, dynamic>{}),
      DefaultValue(42),
    );
  });

  test('@Default does not imply a @JsonKey if one is already specified', () {
    expect(
      DefaultValueJsonKey.fromJson(<String, dynamic>{}),
      DefaultValueJsonKey(21),
    );
  });

  group('generic json', () {
    test('fromJson', () {
      expect(
        Generic<int>.fromJson(<String, dynamic>{'a': 42}),
        Generic(42),
      );
    });

    test('tear-off', () {
      Generic<int> Function(Map<String, Object>) fromJson = $Generic.fromJson;

      expect(
        fromJson(<String, dynamic>{'a': 42}),
        Generic(42),
      );
    });

    group('with argument factories', () {
      test('fromJson', () {
        expect(
          GenericWithArgumentFactories<GenericValue>.fromJson(
            <String, Object>{
              'value': <String, dynamic>{'value': 24},
              'value2': 'abc',
            },
            (json) => GenericValue.fromJson(json as Map<String, dynamic>),
          ),
          GenericWithArgumentFactories<GenericValue>(GenericValue(24), 'abc'),
        );
      });

      test('fromJson with default value for null json', () {
        expect(
          GenericWithArgumentFactories<GenericValue>.fromJson(
            <String, Object>{
              'value2': 'abc',
            },
            (json) => json is Map<String, dynamic>
                ? GenericValue.fromJson(json)
                : GenericValue(51),
          ),
          GenericWithArgumentFactories<GenericValue>(GenericValue(51), 'abc'),
        );
      });

      test('toJson', () {
        expect(
          GenericWithArgumentFactories<GenericValue>(GenericValue(24), 'abc')
              .toJson((value) => value.toJson()),
          <String, Object>{
            'value': <String, dynamic>{'value': 24},
            'value2': 'abc',
          },
        );
      });

      test('tuple fromJson', () {
        expect(
          GenericTupleWithArgumentFactories<int, String>.fromJson(
            <String, Object>{
              'value1': 1,
              'value2': 'value 2',
              'value3': 'hola',
            },
            (json) => json as int,
            (json) => json as String,
          ),
          GenericTupleWithArgumentFactories<int, String>(1, 'value 2', 'hola'),
        );
      });

      test('tuple toJson', () {
        expect(
          GenericTupleWithArgumentFactories<int, String>(1, 'value 2', 'hola')
              .toJson((value) => value, (value) => value),
          <String, Object>{
            'value1': 1,
            'value2': 'value 2',
            'value3': 'hola',
          },
        );
      });

      test('multi ctor default fromJson', () {
        expect(
          GenericMultiCtorWithArgumentFactories<int, String>.fromJson(
            <String, Object>{
              'runtimeType': 'default',
              'first': 1,
              'second': 'value 2',
              'another': 'hola',
            },
            (json) => json as int,
            (json) => json as String,
          ),
          GenericMultiCtorWithArgumentFactories<int, String>(
              1, 'value 2', 'hola'),
        );
      });

      test('multi ctor default toJson', () {
        expect(
          GenericMultiCtorWithArgumentFactories<int, String>(
                  1, 'value 2', 'hola')
              .toJson((value) => value, (value) => value),
          <String, Object>{
            'runtimeType': 'default',
            'first': 1,
            'second': 'value 2',
            'another': 'hola',
          },
        );
      });

      test('multi ctor non-default fromJson', () {
        expect(
          GenericMultiCtorWithArgumentFactories<int, String>.fromJson(
            <String, Object>{
              'runtimeType': 'first',
              'first': 1,
              'another': 'hola',
            },
            (json) => json as int,
            (json) => json as String,
          ),
          GenericMultiCtorWithArgumentFactories<int, String>.first(1, 'hola'),
        );
      });

      test('multi ctor non-default toJson', () {
        expect(
          GenericMultiCtorWithArgumentFactories<int, String>.second(
                  'xyz', 'hola')
              .toJson((value) => value, (value) => value),
          <String, Object>{
            'runtimeType': 'second',
            'second': 'xyz',
            'another': 'hola',
          },
        );
      });
    });
  });

  test('single ctor + json can access properties/copyWith', () {
    final value = Single(42);

    expect(value.a, 42);
    expect(value.copyWith(a: 24), Single(24));
  });

  test('has no issue', () async {
    var errorResult = await jsonFile.session
        .getErrors('/freezed/test/integration/json.freezed.dart');
    expect(errorResult.errors, isEmpty);
  }, skip: true);

  test("single constructor fromJson doesn't require runtimeType", () {
    expect(
      Single.fromJson(<String, dynamic>{
        'a': 42,
      }),
      Single(42),
    );
  });

  test("single constructor toJson doesn't add runtimeType", () {
    expect(
      Single(42).toJson(),
      {
        'a': 42,
      },
    );
  });

  group('toJson', () {
    test('support JsonKeys', () {
      expect(Decorator('42').toJson(), {'what': '42'});
    });

    test('works', () {
      expect(
        Json().toJson(),
        {
          'runtimeType': 'default',
        },
      );

      expect(
        Json.first('42').toJson(),
        {
          'a': '42',
          'runtimeType': 'first',
        },
      );

      expect(
        Json.second(42).toJson(),
        {
          'b': 42,
          'runtimeType': 'second',
        },
      );
    });
  });

  test('throws if runtimeType matches nothing', () {
    expect(
      () => Json.fromJson(<String, dynamic>{}),
      throwsA(isA<FallThroughError>()),
    );
    expect(
      () => Json.fromJson(<String, dynamic>{'runtimeType': 'unknown'}),
      throwsA(isA<FallThroughError>()),
    );
  });

  test('fromJson', () {
    expect(
      Json.fromJson(<String, dynamic>{
        'runtimeType': 'default',
      }),
      Json(),
    );

    expect(
      Json.fromJson(<String, dynamic>{
        'runtimeType': 'first',
        'a': '42',
      }),
      Json.first('42'),
    );

    expect(
      Json.fromJson(<String, dynamic>{
        'runtimeType': 'second',
        'b': 42,
      }),
      Json.second(42),
    );
  });

  test('if no fromJson exists, no constructors are made', () async {
    await expectLater(compile(r'''
import 'json.dart';

void main() {
  Json.fromJson(<String, dynamic>{});
}
'''), completes);

    await expectLater(compile(r'''
import 'json.dart';

void main() {
  NoFirst.fromJson(<String, dynamic>{});
}
'''), throwsCompileError);

    await expectLater(compile(r'''
import 'json.dart';

void main() {
  NoDefault.fromJson(<String, dynamic>{});
}
'''), throwsCompileError);

    await expectLater(compile(r'''
import 'json.dart';

void main() {
  NoSecond.fromJson(<String, dynamic>{});
}
'''), throwsCompileError);
  });
}
