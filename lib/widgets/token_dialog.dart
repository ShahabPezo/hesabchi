import 'package:flutter/material.dart';

/// دیالوگ ورود توکن GitHub.
/// TextEditingController توسط خود این ویجت ساخته و dispose می‌شود، پس
/// هیچ‌وقت وسط بسته‌شدن دیالوگ dispose نمی‌شود.
/// نتیجه: null = انصراف، '' = حذف توکن، غیر خالی = توکن جدید.
Future<String?> showTokenDialog(
  BuildContext context, {
  required String initialValue,
  bool allowDelete = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TokenDialog(
      initialValue: initialValue,
      allowDelete: allowDelete,
    ),
  );
}

class _TokenDialog extends StatefulWidget {
  const _TokenDialog({
    required this.initialValue,
    required this.allowDelete,
  });

  final String initialValue;
  final bool allowDelete;

  @override
  State<_TokenDialog> createState() => _TokenDialogState();
}

class _TokenDialogState extends State<_TokenDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('توکن دسترسی GitHub'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'توکن Personal Access Token (PAT) با دسترسی خواندن به ریپوی sync را وارد کنید.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'ghp_...',
              labelText: 'توکن GitHub',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('انصراف'),
        ),
        if (widget.allowDelete)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text(
              'حذف توکن',
              style: TextStyle(color: Colors.red),
            ),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('ذخیره'),
        ),
      ],
    );
  }
}
