import 'package:flutter/material.dart';
import 'package:flutter_stasis/flutter_stasis.dart';

import '../view_model/auth_runtime_state.dart';
import '../view_model/auth_runtime_view_model.dart';

class AuthRuntimeScreen extends StatefulWidget {
  const AuthRuntimeScreen({super.key, required this.viewModel});

  final AuthRuntimeViewModel viewModel;

  @override
  State<AuthRuntimeScreen> createState() => _AuthRuntimeScreenState();
}

class _AuthRuntimeScreenState extends State<AuthRuntimeScreen> {
  AuthRuntimeViewModel get vm => widget.viewModel;

  late final TextEditingController _passwordController;
  late final TextEditingController _otpController;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _otpController = TextEditingController();
    vm.stateListenable.addListener(_syncControllersFromState);
    _syncControllersFromState();
  }

  @override
  void dispose() {
    vm.stateListenable.removeListener(_syncControllersFromState);
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _syncControllersFromState() {
    _syncController(_passwordController, vm.state.password.readOrNull() ?? '');
    _syncController(_otpController, vm.state.otpCode.readOrNull() ?? '');
  }

  void _syncController(TextEditingController controller, String nextText) {
    if (controller.text == nextText) return;
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SafeData Runtime Demo')),
      body: StasisBuilder<AuthRuntimeState>(
        listenable: vm.stateListenable,
        builder: (context, state, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: const Color(0xFFF4F0FF),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo credentials',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Password: stasis123'),
                      Text('OTP: 654321'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                onChanged: vm.updatePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  helperText: 'SafeData status: ${state.password.status.name}',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: state.isRequestingOtp ? null : vm.requestOtp,
                icon: state.isRequestingOtp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mail_outline),
                label: const Text('Request OTP'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                onChanged: vm.updateOtpCode,
                decoration: InputDecoration(
                  labelText: 'OTP code',
                  border: const OutlineInputBorder(),
                  helperText: 'SafeData status: ${state.otpCode.status.name}',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: state.isVerifyingOtp ? null : vm.verifyOtp,
                icon: state.isVerifyingOtp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user_outlined),
                label: const Text('Verify OTP'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: vm.persistRefreshToken,
                    child: const Text('Persist refresh token'),
                  ),
                  OutlinedButton(
                    onPressed: vm.restoreRefreshToken,
                    child: const Text('Restore refresh token'),
                  ),
                  OutlinedButton(
                    onPressed: vm.deletePersistedRefreshToken,
                    child: const Text('Delete persisted token'),
                  ),
                  OutlinedButton(
                    onPressed: vm.clearInMemorySecrets,
                    child: const Text('Clear in-memory secrets'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _StatusCard(
                title: 'Runtime status',
                lines: [
                  'Lifecycle: ${state.actualState.name}',
                  'Step: ${state.step.name}',
                  'Status: ${state.statusMessage}',
                  if (state.errorMessage != null)
                    'Error: ${state.errorMessage}',
                  if (state.session != null)
                    'Session user: ${state.session!.email}',
                ],
              ),
              const SizedBox(height: 12),
              _StatusCard(
                title: 'Managed fields',
                lines: [
                  'Password: ${state.password.status.name}',
                  'OTP: ${state.otpCode.status.name}',
                  'Access token in memory: ${state.hasAccessTokenInMemory}',
                  'Refresh token in memory: ${state.hasRefreshTokenInMemory}',
                  'Refresh token log view: ${state.refreshToken}',
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final line in lines) ...[
              Text(line),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}
