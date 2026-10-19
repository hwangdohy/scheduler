import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/notification_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/toss_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(
      text: context.read<SettingsService>().geminiApiKey,
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(SettingsService settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: settings.notificationTime,
    );
    if (picked == null) return;
    await settings.setNotificationTime(picked);
    if (settings.notificationsEnabled) {
      await NotificationService.instance.scheduleDailyDiaryReminder(picked);
    }
  }

  Future<void> _toggleNotifications(SettingsService settings, bool value) async {
    await settings.setNotificationsEnabled(value);
    if (value) {
      await NotificationService.instance.scheduleDailyDiaryReminder(settings.notificationTime);
    } else {
      await NotificationService.instance.cancelDiaryReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionLabel('알림'),
          TossCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('일기 작성 알림', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Switch(
                      value: settings.notificationsEnabled,
                      onChanged: (v) => _toggleNotifications(settings, v),
                    ),
                  ],
                ),
                if (settings.notificationsEnabled) ...[
                  const Divider(height: 24),
                  GestureDetector(
                    onTap: () => _pickTime(settings),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('알림 시간')),
                        Text(
                          settings.notificationTime.format(context),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('화면'),
          TossCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('글자 크기', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final size in AppFontSize.values) ...[
                      Expanded(
                        child: _FontSizeOption(
                          size: size,
                          selected: settings.fontSize == size,
                          onTap: () => settings.setFontSize(size),
                        ),
                      ),
                      if (size != AppFontSize.values.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('AI 요약'),
          TossCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gemini API 키', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                  '일기 요약 기능을 사용하려면 Gemini API 키가 필요해요.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'API 키 붙여넣기'),
                  onSubmitted: (v) => settings.setGeminiApiKey(v.trim()),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => settings.setGeminiApiKey(_apiKeyController.text.trim()),
                    child: const Text('저장'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }
}

class _FontSizeOption extends StatelessWidget {
  const _FontSizeOption({required this.size, required this.selected, required this.onTap});
  final AppFontSize size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          size.label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
