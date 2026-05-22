class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入邮箱';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return '邮箱格式不正确';
    }
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入用户名';
    }
    if (value.trim().length < 3) {
      return '用户名至少3个字符';
    }
    if (value.trim().length > 30) {
      return '用户名最多30个字符';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < 8) {
      return '密码至少8个字符';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return '请确认密码';
    }
    if (value != original) {
      return '两次输入的密码不一致';
    }
    return null;
  }

  static String? notEmpty(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName不能为空';
    }
    return null;
  }

  static String? maxLength(String? value, int max, {required String fieldName}) {
    if (value != null && value.length > max) {
      return '$fieldName最多$max个字符';
    }
    return null;
  }
}
