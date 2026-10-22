import 'package:demo1/features/network_calculator/data/subnet_calculator.dart';
import 'package:demo1/features/network_calculator/viewmodel/subnet_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final calculator = SubnetCalculator();
  test('普通 /24 与非整字节 /20 子网范围', () {
    final a = calculator.calculate(['192', '168', '10', '1'], 24);
    expect(a.mask, '255.255.255.0');
    expect(a.network, '192.168.10.0');
    expect(a.broadcast, '192.168.10.255');
    expect(a.range, '192.168.10.1 ~ 192.168.10.254');
    expect(a.usableHosts, 254);
    final b = calculator.calculate(['172', '16', '31', '200'], 20);
    expect(b.mask, '255.255.240.0');
    expect(b.network, '172.16.16.0');
    expect(b.broadcast, '172.16.31.255');
    expect(b.usableHosts, 4094);
  });
  test('边界 /0、/1、/30、/31、/32 及高位地址', () {
    final all = calculator.calculate(['255', '255', '255', '255'], 0);
    expect(all.totalHosts, 4294967296);
    expect(all.range, '0.0.0.1 ~ 255.255.255.254');
    expect(all.mask, '0.0.0.0');
    final half = calculator.calculate(['255', '255', '255', '255'], 1);
    expect(half.network, '128.0.0.0');
    expect(half.totalHosts, 2147483648);
    final small = calculator.calculate(['192', '168', '0', '7'], 30);
    expect(small.range, '192.168.0.5 ~ 192.168.0.6');
    expect(small.broadcast, '192.168.0.7');
    final pair = calculator.calculate(['192', '168', '0', '7'], 31);
    expect(pair.range, '192.168.0.6 ~ 192.168.0.7');
    expect(pair.usableHosts, 2);
    expect(pair.broadcast, isNull);
    final single = calculator.calculate(['255', '255', '255', '255'], 32);
    expect(single.range, '255.255.255.255 ~ 255.255.255.255');
    expect(single.mask, '255.255.255.255');
    expect(single.usableHosts, 1);
    expect(single.broadcast, isNull);
  });
  test('无效地址和前缀不能返回成功结果', () {
    for (final part in ['', '256', '-1', '1.5', 'abc', ' 1', '1234']) {
      expect(
        () => calculator.calculate(['192', '168', '1', part], 24),
        throwsFormatException,
      );
    }
    expect(() => calculator.calculate(['1'], 24), throwsFormatException);
    for (final prefix in [-1, 33]) {
      expect(
        () => calculator.calculate(['1', '2', '3', '4'], prefix),
        throwsFormatException,
      );
    }
  });
  test('输入错误清除旧结果，重新进入恢复默认值', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(subnetProvider, (_, _) {});
    final vm = container.read(subnetProvider.notifier);
    vm.setOctet(0, '');
    expect(container.read(subnetProvider).result, isNull);
    expect(container.read(subnetProvider).error, isNotNull);
    vm.setOctet(0, '10');
    vm.setPrefix(32);
    expect(container.read(subnetProvider).result?.usableHosts, 1);
    subscription.close();
    await container.pump();
    expect(container.read(subnetProvider).prefix, 24);
    expect(container.read(subnetProvider).octets.first, '192');
  });
}
