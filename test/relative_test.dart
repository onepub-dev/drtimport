import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('relative', () {
    expect(
        p.relative('/home/bsutton/git/drtimport/lib/util/tmp1/fred1.dart',
            from: p.dirname(
                '/home/bsutton/git/drtimport/lib/util/tmp2/fred2.dart')),
        '../tmp1/fred1.dart');

    expect(
        p.relative('/home/bsutton/git/drtimport/lib/util/tmp1/fred1.dart',
            from: p.dirname(
                '/home/bsutton/git/drtimport/lib/util/tmp2/fred2.dart')),
        '../tmp1/fred1.dart');

    expect(
        p.relative('/home/bsutton/git/drtimport/lib/util/tmp1/fred1.dart',
            from: p.dirname(
                '/home/bsutton/git/drtimport/lib/util/tmp1/fred2.dart')),
        'fred1.dart');
  });
}
