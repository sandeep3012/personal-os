/// Personal OS — Platform Core
///
/// Foundational types, patterns, and abstractions shared by every package in
/// the Personal OS monorepo.
///
/// ## Dependency rule
/// `platform_core` depends only on the Dart SDK. It must never import from
/// Runtime, Services, Features, or any Flutter UI layer.
///
/// ## Public API
///
/// | Layer        | Import path                                    |
/// |---|---|
/// | Result       | `platform_core/result/result.dart`             |
/// | Exceptions   | `platform_core/exceptions/exceptions.dart`     |
/// | Logging      | `platform_core/logging/logging.dart`           |
/// | Config       | `platform_core/config/config.dart`             |
/// | Environment  | `platform_core/environment/environment.dart`   |
/// | DI           | `platform_core/di/di.dart`                     |
/// | Constants    | `platform_core/constants/constants.dart`       |
/// | Extensions   | `platform_core/extensions/extensions.dart`     |
/// | Types        | `platform_core/types/types.dart`               |
/// | Utils        | `platform_core/utils/utils.dart`               |
library;

export 'package:platform_core/config/config.dart';
export 'package:platform_core/constants/constants.dart';
export 'package:platform_core/di/di.dart';
export 'package:platform_core/environment/environment.dart';
export 'package:platform_core/exceptions/exceptions.dart';
export 'package:platform_core/extensions/extensions.dart';
export 'package:platform_core/logging/logging.dart';
export 'package:platform_core/result/result.dart';
export 'package:platform_core/types/types.dart';
export 'package:platform_core/utils/utils.dart';
