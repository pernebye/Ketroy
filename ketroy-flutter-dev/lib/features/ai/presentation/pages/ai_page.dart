import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ketroy_app/core/common/widgets/auth_required_dialog.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/ai/data/models/chat_message_model.dart';
import 'package:ketroy_app/features/ai/presentation/bloc/ai_bloc.dart';
import 'package:ketroy_app/features/ai/presentation/pages/label_scanner_sheet.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';
import 'package:ketroy_app/services/localization/localization_service.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late AnimationController _messageController;
  late AnimationController _transitionController;
  late List<Animation<double>> _messageAnimations;
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  // Кэшированное состояние авторизации
  bool? _isLoggedIn;
  bool _isCheckingAuth = true;
  int _lastAuthVersion = -1;

  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _lightGreen = Color(0xFF5A6F2B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);
  static const Color _cardBg = Color(0xFFF5F7F0);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _messageAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _messageController,
          curve: Interval(
            index * 0.2,
            0.4 + index * 0.2,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _messageController.forward();
    
    // Проверяем авторизацию при инициализации
    _checkAuth();
  }

  /// Проверка авторизации с кэшированием результата
  Future<void> _checkAuth() async {
    final isLoggedIn = await UserDataManager.isUserLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isCheckingAuth = false;
        _lastAuthVersion = UserDataManager.authStateNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    _messageController.dispose();
    _transitionController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String cleanAnalysisText(String text) {
    return text
        .replaceAll('\\n', '\n')
        .replaceAll('\\t', '    ')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('###', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .trim();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Получаем правильный код языка для AI напрямую из LocalizationService singleton
    final locService = serviceLocator<LocalizationService>();
    final languageCode = locService.getLanguageCodeForAI();
    debugPrint('💬 AiPage: Sending message with language: $languageCode');
    
    context.read<AiBloc>().add(SendChatMessage(
          message: text,
          languageCode: languageCode,
        ));

    _textController.clear();
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: _accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(Icons.camera_alt, color: _primaryGreen),
                ),
                title: Text(l10n.takePhoto),
                onTap: () {
                  Navigator.pop(ctx);
                  _captureImage(ImageSource.camera);
                },
              ),
              SizedBox(height: 8.h),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: _accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(Icons.photo_library, color: _primaryGreen),
                ),
                title: Text(l10n.chooseFromGallery),
                onTap: () {
                  Navigator.pop(ctx);
                  _captureImage(ImageSource.gallery);
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        final l10n = AppLocalizations.of(context)!;
        // Получаем правильный код языка для AI напрямую из LocalizationService singleton
        final locService = serviceLocator<LocalizationService>();
        final languageCode = locService.getLanguageCodeForAI();
        debugPrint('📷 AiPage: Capturing image with language: $languageCode');
        
        context.read<AiBloc>().add(SendChatImage(
              imageFile: File(photo.path),
              languageCode: languageCode,
              message: l10n.analyzeThisLabel,
            ));
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _goToMainScreen() {
    // Сначала показываем навбар
    NavScreen.globalKey.currentState?.setNavBarVisibility(true);
    // Очищаем состояние чата
    context.read<AiBloc>().add(CloseChat());
    // Переходим на главный экран (витрину)
    NavScreen.globalKey.currentState?.switchToTab(0);
  }

  Widget _buildLoginDialog(BuildContext context, AppLocalizations l10n) {
    return AuthRequiredDialog(
      title: l10n.authRequired,
      message: l10n.aiAuthRequired,
      onCancel: () {
        NavScreen.globalKey.currentState?.switchToTab(0);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _cardBg,
        resizeToAvoidBottomInset: true,
        body: ValueListenableBuilder<int>(
          valueListenable: UserDataManager.authStateNotifier,
          builder: (context, authVersion, _) {
            // Проверяем авторизацию только если версия изменилась
            if (authVersion != _lastAuthVersion && !_isCheckingAuth) {
              // Запускаем проверку асинхронно, не блокируя UI
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _checkAuth();
              });
            }

            // Показываем загрузку только при первой проверке
            if (_isCheckingAuth && _isLoggedIn == null) {
              return const Loader();
            }

            final isLoggedIn = _isLoggedIn ?? false;

            if (!isLoggedIn) {
              return _buildLoginDialog(context, l10n);
            }

            return BlocConsumer<AiBloc, AiState>(
              listener: (context, state) {
                if (state.isFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message ?? l10n.errorOccurred),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
                if (state.chatMessages.isNotEmpty) {
                  _scrollToBottom();
                }
                
                // Управление видимостью навбара при изменении состояния чата
                NavScreen.globalKey.currentState?.setNavBarVisibility(!state.isChatActive);
                
                // Анимация перехода к чату
                if (state.isChatActive && _transitionController.value == 0) {
                  _transitionController.forward();
                }
                
                // Сброс анимации при закрытии чата
                if (!state.isChatActive && _transitionController.value > 0) {
                  _transitionController.reset();
                }
              },
              builder: (context, state) {
                return Stack(
                  children: [
                    _buildBackground(),
                    SafeArea(
                      bottom: false,
                      child: state.isChatActive
                          ? _buildChatMode(state, l10n)
                          : _buildInitialMode(state, l10n),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Начальный режим - сканирование этикетки
  Widget _buildInitialMode(AiState state, AppLocalizations l10n) {
    return Column(
      children: [
        _buildHeader(l10n),
        Expanded(child: _buildInitialChatArea(state, l10n)),
        _buildBottomPanel(state, l10n),
      ],
    );
  }

  /// Режим чата - после анализа
  Widget _buildChatMode(AiState state, AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        return Column(
          children: [
            // Компактный хедер с кнопкой назад
            _buildChatHeader(l10n),
            // Список сообщений
            Expanded(child: _buildChatMessages(state, l10n)),
            // Поле ввода
            _buildChatInput(state, l10n),
          ],
        );
      },
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _darkBg,
            _primaryGreen.withValues(alpha: 0.3),
            _cardBg,
          ],
          stops: const [0.0, 0.25, 0.45],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.08);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_accentGreen, _lightGreen, _primaryGreen],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accentGreen.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KETROY AI',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accentGreen,
                            boxShadow: [
                              BoxShadow(
                                color: _accentGreen.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          l10n.virtualAssistant,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white70,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(double.infinity, 20.h),
                painter: WavePainter(
                  animation: _waveController.value,
                  color: _accentGreen.withValues(alpha: 0.3),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Компактный хедер для режима чата
  Widget _buildChatHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 20.w, 12.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_darkBg, _primaryGreen],
        ),
      ),
      child: Row(
        children: [
          // Кнопка назад
          IconButton(
            onPressed: _goToMainScreen,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 22.w,
            ),
          ),
          // AI аватар
          Container(
            width: 40.w,
            height: 40.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_accentGreen, _lightGreen],
              ),
            ),
            child: Center(
              child: Text(
                'AI',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KETROY AI',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accentGreen,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      l10n.virtualAssistant,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Кнопка нового чата
          IconButton(
            onPressed: () {
              context.read<AiBloc>().add(ClearChat());
            },
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
              size: 22.w,
            ),
            tooltip: 'Новый чат',
          ),
        ],
      ),
    );
  }

  /// Список сообщений чата
  Widget _buildChatMessages(AiState state, AppLocalizations l10n) {
    return Container(
      color: _cardBg,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
        itemCount: state.chatMessages.length,
        itemBuilder: (context, index) {
          final message = state.chatMessages[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildChatBubble(message, l10n),
          );
        },
      ),
    );
  }

  /// Пузырь сообщения
  Widget _buildChatBubble(ChatMessage message, AppLocalizations l10n) {
    final isUser = message.role == MessageRole.user;

    if (message.isLoading) {
      return _buildTypingIndicator(l10n);
    }

    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          _buildAiAvatar(),
          SizedBox(width: 8.w),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: 280.w),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isUser ? _primaryGreen : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isUser ? 18.r : 4.r),
                topRight: Radius.circular(isUser ? 4.r : 18.r),
                bottomLeft: Radius.circular(18.r),
                bottomRight: Radius.circular(18.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Если есть изображение
                if (message.imageFile != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.file(
                      message.imageFile!,
                      width: 200.w,
                      height: 150.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (message.content.isNotEmpty) SizedBox(height: 8.h),
                ],
                // Текст сообщения
                if (message.content.isNotEmpty)
                  Text(
                    cleanAnalysisText(message.content),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isUser ? Colors.white : Colors.black87,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isUser) ...[
          SizedBox(width: 8.w),
          _buildUserAvatar(),
        ],
      ],
    );
  }

  Widget _buildAiAvatar() {
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_lightGreen, _primaryGreen],
        ),
      ),
      child: Center(
        child: Text(
          'AI',
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _accentGreen.withValues(alpha: 0.2),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 18.w,
          color: _primaryGreen,
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAiAvatar(),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4.r),
              topRight: Radius.circular(18.r),
              bottomLeft: Radius.circular(18.r),
              bottomRight: Radius.circular(18.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(0),
              SizedBox(width: 4.w),
              _buildDot(1),
              SizedBox(width: 4.w),
              _buildDot(2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final delay = index * 0.2;
        final animValue = ((_pulseController.value + delay) % 1.0);
        final scale = 0.6 + (math.sin(animValue * math.pi) * 0.4);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryGreen.withValues(alpha: 0.6),
            ),
          ),
        );
      },
    );
  }

  /// Поле ввода сообщения
  Widget _buildChatInput(AiState state, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Кнопка камеры
            GestureDetector(
              onTap: state.isSendingMessage ? null : _pickAndSendImage,
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: _accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: state.isSendingMessage ? Colors.grey : _primaryGreen,
                  size: 22.w,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            // Поле ввода
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  enabled: !state.isSendingMessage,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 1,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.typeMessage,
                    hintStyle: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.grey.shade500,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            // Кнопка отправки
            GestureDetector(
              onTap: state.isSendingMessage ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: state.isSendingMessage
                        ? [Colors.grey.shade400, Colors.grey.shade500]
                        : [_lightGreen, _primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: state.isSendingMessage
                      ? []
                      : [
                          BoxShadow(
                            color: _primaryGreen.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialChatArea(AiState state, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
          children: [
            _buildAnimatedMessage(
              index: 0,
              child: _buildAiMessage(l10n.aiGreeting, isFirst: true),
            ),
            SizedBox(height: 12.h),
            _buildAnimatedMessage(
              index: 1,
              child: _buildAiMessage(l10n.aiInstructions),
            ),
            if (state.isLoading) ...[
              SizedBox(height: 16.h),
              _buildLoadingMessage(l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMessage({required int index, required Widget child}) {
    if (index >= _messageAnimations.length) {
      return child;
    }
    return AnimatedBuilder(
      animation: _messageAnimations[index],
      builder: (context, _) {
        final value = _messageAnimations[index].value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildAiMessage(String text, {bool isFirst = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_lightGreen, _primaryGreen],
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'AI',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4.r),
                topRight: Radius.circular(20.r),
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.black87,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        SizedBox(width: 40.w),
      ],
    );
  }

  Widget _buildLoadingMessage(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_lightGreen, _primaryGreen],
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 20.w,
              height: 20.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4.r),
              topRight: Radius.circular(20.r),
              bottomLeft: Radius.circular(20.r),
              bottomRight: Radius.circular(20.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(0),
              SizedBox(width: 4.w),
              _buildDot(1),
              SizedBox(width: 4.w),
              _buildDot(2),
              SizedBox(width: 12.w),
              Text(
                l10n.analyzing,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel(AiState state, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: _primaryGreen,
                    size: 20.w,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      l10n.pointCameraAtLabel,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.black54,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: state.isLoading
                  ? null
                  : () {
                      showLabelScannerSheet(context);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 18.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: state.isLoading
                        ? [Colors.grey.shade400, Colors.grey.shade500]
                        : [_lightGreen, _primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: state.isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: _primaryGreen.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 24.w,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      state.isLoading ? l10n.processing : l10n.scanLabel,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: NavBar.getBottomPadding(context)),
          ],
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double animation;
  final Color color;

  WavePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final waveHeight = size.height * 0.4;
    final waveLength = size.width / 2;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 +
          math.sin((x / waveLength * 2 * math.pi) + (animation * 2 * math.pi)) *
              waveHeight;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path2 = Path();
    path2.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 +
          math.sin((x / waveLength * 2 * math.pi) -
                  (animation * 2 * math.pi) +
                  0.5) *
              (waveHeight * 0.6);
      path2.lineTo(x, y);
    }

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
