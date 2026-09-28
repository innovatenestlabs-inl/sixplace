import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Validator signature used by Sixplace form helpers.
typedef SPFormValidator<T> = String? Function(T? value);

/// Common validators that can be composed without a state-management package.
abstract final class SPValidators {
  /// Requires a non-empty string after trimming whitespace.
  static SPFormValidator<String> required([
    String message = 'This field is required.',
  ]) => (value) => value == null || value.trim().isEmpty ? message : null;

  /// Validates an email-like value while allowing an empty optional field.
  static SPFormValidator<String> email([
    String message = 'Enter a valid email address.',
  ]) => (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text);
    return valid ? null : message;
  };

  /// Requires at least [length] characters when the field is non-empty.
  static SPFormValidator<String> minLength(
    int length, [
    String? message,
  ]) {
    if (length < 0) {
      throw ArgumentError.value(length, 'length', 'Must not be negative.');
    }
    return (value) {
      final text = value ?? '';
      if (text.isEmpty || text.length >= length) return null;
      return message ?? 'Enter at least $length characters.';
    };
  }

  /// Limits a non-empty value to [length] characters.
  static SPFormValidator<String> maxLength(
    int length, [
    String? message,
  ]) {
    if (length < 0) {
      throw ArgumentError.value(length, 'length', 'Must not be negative.');
    }
    return (value) {
      final text = value ?? '';
      if (text.isEmpty || text.length <= length) return null;
      return message ?? 'Enter no more than $length characters.';
    };
  }

  /// Requires a non-empty value to match [pattern].
  static SPFormValidator<String> pattern(
    RegExp pattern, {
    String message = 'Enter a valid value.',
  }) => (value) {
    final text = value ?? '';
    if (text.isEmpty) return null;
    return pattern.hasMatch(text) ? null : message;
  };

  /// Requires a numeric value to be greater than or equal to [minimum].
  static SPFormValidator<String> minNumber(
    num minimum, {
    String? invalidNumberMessage,
    String? minimumMessage,
  }) => (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final number = num.tryParse(text);
    if (number == null) {
      return invalidNumberMessage ?? 'Enter a valid number.';
    }
    return number >= minimum
        ? null
        : minimumMessage ?? 'Enter a value of at least $minimum.';
  };

  /// Requires a numeric value to be less than or equal to [maximum].
  static SPFormValidator<String> maxNumber(
    num maximum, {
    String? invalidNumberMessage,
    String? maximumMessage,
  }) => (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final number = num.tryParse(text);
    if (number == null) {
      return invalidNumberMessage ?? 'Enter a valid number.';
    }
    return number <= maximum
        ? null
        : maximumMessage ?? 'Enter a value of at most $maximum.';
  };

  /// Runs validators in order and returns the first validation message.
  static SPFormValidator<T> compose<T>(Iterable<SPFormValidator<T>> validators) {
    final saved = List<SPFormValidator<T>>.unmodifiable(validators);
    return (value) {
      for (final validator in saved) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}

/// Coordinates validation, submission state and duplicate-submit protection.
///
/// The controller deliberately does not perform navigation or show feedback.
/// Applications can observe [isSubmitting] and [lastError] with any state
/// management approach, or use [SPSubmitButton].
class SPFormController extends ChangeNotifier {
  bool _isSubmitting = false;
  Object? _lastError;
  bool _disposed = false;

  /// Whether a submission started through [submit] is currently running.
  bool get isSubmitting => _isSubmitting;

  /// The most recent exception thrown by the submitted action, if any.
  Object? get lastError => _lastError;

  /// Validates, saves and submits a form once.
  ///
  /// Returns null when validation fails or another submission is already in
  /// progress. Exceptions from [action] are stored in [lastError] and rethrown.
  Future<T?> submit<T>({
    required GlobalKey<FormState> formKey,
    required Future<T> Function() action,
    BuildContext? context,
    bool validate = true,
    bool save = true,
    bool unfocus = true,
  }) async {
    if (_isSubmitting) return null;

    final form = formKey.currentState;
    if (form == null) {
      throw StateError(
        'The supplied formKey is not attached to an active Form widget.',
      );
    }

    if (validate && !form.validate()) return null;
    if (save) form.save();
    if (unfocus && context != null) {
      FocusScope.of(context).unfocus();
    }

    _lastError = null;
    _isSubmitting = true;
    _safeNotifyListeners();

    try {
      return await action();
    } catch (error) {
      _lastError = error;
      rethrow;
    } finally {
      _isSubmitting = false;
      _safeNotifyListeners();
    }
  }

  /// Clears [lastError] and notifies listeners when necessary.
  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    _safeNotifyListeners();
  }

  /// Resets the attached form and clears controller error state.
  void reset(GlobalKey<FormState> formKey) {
    formKey.currentState?.reset();
    _lastError = null;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Text input with sensible Material form defaults and Sixplace naming.
class SPTextFormField extends StatelessWidget {
  /// Creates a text form field.
  const SPTextFormField({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.label,
    this.hint,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.onFieldSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autovalidateMode,
    this.decoration,
  }) : assert(
         controller == null || initialValue == null,
         'controller and initialValue cannot both be supplied.',
       ),
       assert(maxLines == null || maxLines > 0),
       assert(minLines == null || minLines > 0),
       assert(
         maxLines == null || minLines == null || maxLines >= minLines,
         'maxLines must be greater than or equal to minLines.',
       );

  /// Optional text editing controller.
  final TextEditingController? controller;

  /// Initial text used when no [controller] is supplied.
  final String? initialValue;

  /// Optional focus node.
  final FocusNode? focusNode;

  /// Input label.
  final String? label;

  /// Input hint.
  final String? hint;

  /// Optional helper text.
  final String? helperText;

  /// Leading decoration widget.
  final Widget? prefixIcon;

  /// Trailing decoration widget.
  final Widget? suffixIcon;

  /// Field validator.
  final FormFieldValidator<String>? validator;

  /// Called when the parent form saves.
  final FormFieldSetter<String>? onSaved;

  /// Called whenever the value changes.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard submits the field.
  final ValueChanged<String>? onFieldSubmitted;

  /// Keyboard layout hint.
  final TextInputType? keyboardType;

  /// Keyboard action hint.
  final TextInputAction? textInputAction;

  /// Optional input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Platform autofill hints.
  final Iterable<String>? autofillHints;

  /// Whether the text is obscured.
  final bool obscureText;

  /// Whether user interaction is enabled.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Whether autocorrect is enabled.
  final bool autocorrect;

  /// Whether input suggestions are enabled.
  final bool enableSuggestions;

  /// Maximum visible lines, or null for an expanding multiline field.
  final int? maxLines;

  /// Minimum visible lines.
  final int? minLines;

  /// Optional character limit.
  final int? maxLength;

  /// Automatic validation behavior.
  final AutovalidateMode? autovalidateMode;

  /// Optional complete input decoration. Label/hint/helper/icon properties
  /// override the corresponding values on this decoration when supplied.
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final base = decoration ?? const InputDecoration();
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      maxLines: obscureText ? 1 : maxLines,
      minLines: obscureText ? null : minLines,
      maxLength: maxLength,
      autovalidateMode: autovalidateMode,
      decoration: base.copyWith(
        labelText: label ?? base.labelText,
        hintText: hint ?? base.hintText,
        helperText: helperText ?? base.helperText,
        prefixIcon: prefixIcon ?? base.prefixIcon,
        suffixIcon: suffixIcon ?? base.suffixIcon,
      ),
    );
  }
}

/// Dropdown input integrated with Flutter's [Form] validation lifecycle.
class SPDropdownFormField<T> extends StatelessWidget {
  /// Creates a dropdown form field.
  const SPDropdownFormField({
    super.key,
    required this.items,
    required this.onChanged,
    this.initialValue,
    this.label,
    this.hint,
    this.validator,
    this.onSaved,
    this.enabled = true,
    this.isExpanded = true,
    this.autovalidateMode,
    this.decoration,
  });

  /// Available dropdown items.
  final List<DropdownMenuItem<T>> items;

  /// Initial selected value.
  final T? initialValue;

  /// Called when the selected value changes.
  final ValueChanged<T?> onChanged;

  /// Input label.
  final String? label;

  /// Optional hint widget.
  final Widget? hint;

  /// Field validator.
  final FormFieldValidator<T>? validator;

  /// Called when the parent form saves.
  final FormFieldSetter<T>? onSaved;

  /// Whether the field accepts user input.
  final bool enabled;

  /// Whether the dropdown fills the available horizontal space.
  final bool isExpanded;

  /// Automatic validation behavior.
  final AutovalidateMode? autovalidateMode;

  /// Optional input decoration.
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final base = decoration ?? const InputDecoration();
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      items: items,
      onChanged: enabled ? onChanged : null,
      hint: hint,
      validator: validator,
      onSaved: onSaved,
      isExpanded: isExpanded,
      autovalidateMode: autovalidateMode,
      decoration: base.copyWith(labelText: label ?? base.labelText),
    );
  }
}

/// Boolean form input with validation and save support.
class SPCheckboxFormField extends FormField<bool> {
  /// Creates a checkbox form field.
  SPCheckboxFormField({
    super.key,
    bool initialValue = false,
    required String title,
    String? subtitle,
    ValueChanged<bool>? onChanged,
    FormFieldValidator<bool>? validator,
    FormFieldSetter<bool>? onSaved,
    bool enabled = true,
    AutovalidateMode? autovalidateMode,
    ListTileControlAffinity controlAffinity = ListTileControlAffinity.leading,
  }) : super(
         initialValue: initialValue,
         validator: validator,
         onSaved: onSaved,
         autovalidateMode: autovalidateMode,
         enabled: enabled,
         builder: (state) => Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             CheckboxListTile(
               value: state.value ?? false,
               onChanged: enabled
                   ? (value) {
                       final resolved = value ?? false;
                       state.didChange(resolved);
                       onChanged?.call(resolved);
                     }
                   : null,
               title: Text(title),
               subtitle: subtitle == null ? null : Text(subtitle),
               controlAffinity: controlAffinity,
               contentPadding: EdgeInsets.zero,
             ),
             if (state.hasError)
               Padding(
                 padding: const EdgeInsetsDirectional.only(start: 12, top: 4),
                 child: Text(
                   state.errorText!,
                   style: TextStyle(
                     color: Theme.of(state.context).colorScheme.error,
                     fontSize: 12,
                   ),
                 ),
               ),
           ],
         ),
       );
}

/// Submit button that observes an [SPFormController].
class SPSubmitButton extends StatelessWidget {
  /// Creates a button that disables itself and shows progress during submit.
  const SPSubmitButton({
    super.key,
    required this.controller,
    required this.onPressed,
    required this.label,
    this.busyLabel,
    this.icon,
    this.expand = false,
  });

  /// Controller whose [SPFormController.isSubmitting] state is observed.
  final SPFormController controller;

  /// Called when the button is pressed while not submitting.
  final VoidCallback? onPressed;

  /// Normal button label.
  final String label;

  /// Optional label displayed while submitting.
  final String? busyLabel;

  /// Optional leading icon shown only while idle.
  final Widget? icon;

  /// Whether the button should occupy the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final busy = controller.isSubmitting;
      final child = Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy) ...[
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
          ] else if (icon != null) ...[
            icon!,
            const SizedBox(width: 8),
          ],
          Text(busy ? busyLabel ?? label : label),
        ],
      );

      return FilledButton(
        onPressed: busy ? null : onPressed,
        child: child,
      );
    },
  );
}
