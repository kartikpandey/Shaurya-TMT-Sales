import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/geo_point.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../providers/auth_providers.dart';

/// Mandatory one-time gate: an account with no registered home coordinates is
/// routed here straight after login and cannot reach the dashboard until the
/// coordinates are saved.
class RegisterHomeCoordinatesScreen extends ConsumerStatefulWidget {
  const RegisterHomeCoordinatesScreen({super.key});

  @override
  ConsumerState<RegisterHomeCoordinatesScreen> createState() =>
      _RegisterHomeCoordinatesScreenState();
}

class _RegisterHomeCoordinatesScreenState
    extends ConsumerState<RegisterHomeCoordinatesScreen> {
  static const _locationService = LocationService();

  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _capturing = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _capture();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    setState(() {
      _capturing = true;
      _error = null;
    });

    final point = await _locationService.current();
    if (!mounted) return;

    setState(() {
      _capturing = false;
      if (point != null) {
        _latController.text = point.lat.toStringAsFixed(6);
        _lngController.text = point.lng.toStringAsFixed(6);
      } else {
        _error =
            'Could not read GPS. Check location permission/enable the GPS '
            'service, or enter the coordinates manually.';
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final point = GeoPoint(
      lat: double.parse(_latController.text.trim()),
      lng: double.parse(_lngController.text.trim()),
    );

    await ref.read(authStateProvider.notifier).saveHomeCoordinates(point);
    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Location'), leading: const SizedBox()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha:0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryOrange.withValues(alpha:0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.home_work_outlined,
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Register your home coordinates',
                            style: AppTextStyles.titleLarge(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'This is a one-time setup for your account. It anchors '
                        'your base location for reporting - it does NOT restrict '
                        'where you can punch in or check in.',
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_capturing)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  AppCoordinateField(
                    controller: _latController,
                    label: 'Latitude',
                    hint: '18.520400',
                  ),
                  const SizedBox(height: 14),
                  AppCoordinateField(
                    controller: _lngController,
                    label: 'Longitude',
                    hint: '73.856700',
                  ),
                ],

                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _capturing ? null : _capture,
                  icon: const Icon(Icons.my_location),
                  label: Text(_capturing ? 'Locating...' : 'Capture current location'),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.warningRed),
                  ),
                ],

                const SizedBox(height: 24),
                CustomButton(
                  label: 'Save & Continue',
                  isLoading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppCoordinateField extends StatelessWidget {
  const AppCoordinateField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium(context)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: InputDecoration(hintText: hint),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Required';
            final parsed = double.tryParse(text);
            if (parsed == null) return 'Enter a valid number';
            if (label == 'Latitude' && (parsed < -90 || parsed > 90)) {
              return 'Latitude must be between -90 and 90';
            }
            if (label == 'Longitude' && (parsed < -180 || parsed > 180)) {
              return 'Longitude must be between -180 and 180';
            }
            return null;
          },
        ),
      ],
    );
  }
}
