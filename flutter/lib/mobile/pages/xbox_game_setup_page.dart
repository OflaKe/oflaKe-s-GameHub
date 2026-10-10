import 'package:flutter/material.dart';
import 'package:flutter_hbb/mobile/widgets/xbox_gamepad_status.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import '../../common.dart';
import 'home_page.dart';

class XboxGameSetupPage extends StatelessWidget implements PageShape {
  XboxGameSetupPage({Key? key}) : super(key: key);

  @override
  final String title = 'Setup';

  @override
  final Widget icon = const Icon(Icons.tune_rounded);

  @override
  final List<Widget> appBarActions = [];

  @override
  Widget build(BuildContext context) => const XboxGameSetupPanel();
}

class XboxGameSetupPanel extends StatefulWidget {
  const XboxGameSetupPanel({this.showHeading = true, Key? key})
      : super(key: key);

  final bool showHeading;

  @override
  State<XboxGameSetupPanel> createState() => _XboxGameSetupPanelState();
}

class _XboxGameSetupPanelState extends State<XboxGameSetupPanel> {
  @override
  void initState() {
    super.initState();
    _refreshControllers();
  }

  Future<void> _refreshControllers() async {
    final devices =
        await gFFI.invokeMethodWithResult<List<dynamic>>('get_xbox_gamepads');
    if (devices == null || !mounted) return;
    connectedGamepadDevices.value = devices
        .whereType<Map>()
        .map((device) => Map<String, dynamic>.from(device))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gFFI.ffiModel,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (widget.showHeading) ...[
            Text(
              'Setup manete',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 5),
            Text(
      'Manetele conectate și display-ul pentru jocul remote.',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 18),
          ],
          _buildControllerCard(context),
          const SizedBox(height: 14),
          _buildDisplayCard(context),
        ],
      ),
    );
  }

  Widget _buildControllerCard(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: connectedGamepadDevices,
      builder: (context, devices, _) => _SetupCard(
        title: 'Manete conectate',
        subtitle: '${devices.length} conectat${devices.length == 1 ? '' : 'e'}',
        leading: Icons.sports_esports_rounded,
        action: IconButton(
          tooltip: 'Refresh',
          onPressed: _refreshControllers,
          icon: const Icon(Icons.refresh_rounded),
        ),
        child: devices.isEmpty
            ? const _EmptyStatus(
                icon: Icons.usb_off_rounded,
                text: 'Conectează o manetă la telefon.',
              )
            : Column(
                children: [
                  for (var i = 0; i < devices.length; i++) ...[
                    if (i > 0) const Divider(height: 18),
                    _ControllerRow(index: i + 1, device: devices[i]),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildDisplayCard(BuildContext context) {
    final pi = gFFI.ffiModel.pi;
    final connected = pi.isSet.value && pi.displays.isNotEmpty;
    final display = connected ? pi.tryGetDisplay() : null;
    return _SetupCard(
      title: 'Remote display',
      subtitle:
          connected ? 'Conectat la ${pi.hostname}' : 'Așteaptă conexiunea',
      leading: Icons.desktop_windows_rounded,
      child: !connected || display == null
          ? const _EmptyStatus(
              icon: Icons.link_off_rounded,
              text: 'Conectează-te la PC ca să vezi display-ul și rezoluția.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(
                  label: 'Display ${pi.currentDisplay + 1}',
                  value: '${display.width} × ${display.height}',
                ),
                if (pi.displays.length > 1)
                  _InfoLine(label: 'Monitoare', value: '${pi.displays.length}'),
                if (pi.resolutions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Rezoluție',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: pi.resolutions.any((resolution) =>
                            resolution.width == display.width &&
                            resolution.height == display.height)
                        ? '${display.width}x${display.height}'
                        : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: pi.resolutions
                        .map((resolution) => DropdownMenuItem(
                              value: '${resolution.width}x${resolution.height}',
                              child: Text(
                                  '${resolution.width} × ${resolution.height}'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final parts = value.split('x');
                      if (parts.length != 2) return;
                      bind.sessionChangeResolution(
                        sessionId: gFFI.sessionId,
                        display: pi.currentDisplay,
                        width: int.parse(parts[0]),
                        height: int.parse(parts[1]),
                      );
                    },
                  ),
                ],
              ],
            ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final IconData leading;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(leading, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (action != null) action!,
            ]),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ControllerRow extends StatelessWidget {
  const _ControllerRow({required this.index, required this.device});

  final int index;
  final Map<String, dynamic> device;

  @override
  Widget build(BuildContext context) {
    final name = (device['name'] as String?)?.trim();
    return Row(children: [
      const Icon(Icons.sports_esports_outlined, size: 22),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Controller $index',
              style: Theme.of(context).textTheme.titleSmall),
          Text(name == null || name.isEmpty ? 'Controller' : name,
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
      const Icon(Icons.check_circle_rounded, color: Colors.green),
    ]);
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ]),
      );
}

class _EmptyStatus extends StatelessWidget {
  const _EmptyStatus({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 20, color: Theme.of(context).hintColor),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ]);
}
