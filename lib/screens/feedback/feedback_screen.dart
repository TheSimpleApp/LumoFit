import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/feedback_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String _category = 'idea';
  final _messageController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          color: Theme.of(context).colorScheme.onSurface,
          tooltip: 'Cancel',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tell us what you think', style: text.titleLarge)
                  .animate().fadeIn().slideY(begin: 0.06),
              const SizedBox(height: 8),
              Text('We read every submission. Thanks for helping improve FitTravel! 💛',
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 16),
              Text('Category', style: text.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _chip('idea', Icons.lightbulb_outline),
                  _chip('bug', Icons.bug_report_outlined),
                  _chip('other', Icons.chat_bubble_outline),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Your message',
                  hintText: 'Share an idea or describe a bug…',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact (optional)',
                  hintText: 'Email or handle if you want a reply',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.arrow_back, color: colors.primary),
                  label: Text('Cancel', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.primary.withValues(alpha: 0.4)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _RecentList().animate().fadeIn(delay: 250.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String value, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    final selected = _category == value;
    return InkWell(
      onTap: () => setState(() => _category = value),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.15) : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: selected ? colors.primary : colors.outline.withValues(alpha: 0.7), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? colors.primary : colors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(value[0].toUpperCase() + value.substring(1), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: selected ? colors.primary : colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final svc = context.read<FeedbackService>();
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a message'), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await svc.submit(category: _category, message: message, contact: _contactController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for your feedback!'), behavior: SnackBarBehavior.floating));
      if (!mounted) return;
      // Use go_router pop to maintain consistent navigation
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send. Try again.'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _RecentList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final items = context.watch<FeedbackService>().items;
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent submissions', style: text.titleMedium),
        const SizedBox(height: 8),
        ...items.take(5).map((f) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_iconFor(f.category), color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(f.message, style: text.bodyMedium)),
                ],
              ),
            )),
      ],
    );
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'bug':
        return Icons.bug_report_outlined;
      case 'idea':
        return Icons.lightbulb_outline;
      default:
        return Icons.chat_bubble_outline;
    }
  }
}
