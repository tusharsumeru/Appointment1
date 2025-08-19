import 'package:flutter/material.dart';

class PhotoValidationBottomSheet extends StatefulWidget {
  final VoidCallback? onTryAgain;

  const PhotoValidationBottomSheet({
    super.key,
    this.onTryAgain,
  });

  static void show(BuildContext context, {VoidCallback? onTryAgain}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PhotoValidationBottomSheet(onTryAgain: onTryAgain),
    );
  }

  @override
  State<PhotoValidationBottomSheet> createState() => _PhotoValidationBottomSheetState();
}

class _PhotoValidationBottomSheetState extends State<PhotoValidationBottomSheet>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _hasReachedBottom = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    
    _scrollController.addListener(_onScroll);
    _bounceController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 10) {
      if (!_hasReachedBottom) {
        setState(() {
          _hasReachedBottom = true;
        });
      }
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with icon
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF475569), Color(0xFF334155)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          '!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '❗ Hmm, that photo doesn\'t seem right.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'To proceed with your appointment request, please upload a clear photo of yourself only — no group photos, no nature shots, no celebrities, and no Gurudev\'s photo.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Correct Examples Section
                                     Container(
                     width: double.infinity,
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: const Color(0xFFF0FDF4),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: const Color(0xFFBBF7D0)),
                     ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF16A34A),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                                                         const Expanded(
                               child: Text(
                                 'Here\'s what your profile picture\nshould include:',
                                 style: TextStyle(
                                   fontSize: 16,
                                   fontWeight: FontWeight.w600,
                                   color: Color(0xFF166534),
                                 ),
                               ),
                             ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildTag('Clear photo of YOUR face', true),
                            _buildTag('No one else in frame', true),
                            _buildTag('No masks or filters', true),
                            _buildTag('Good lighting', true),
                            _buildTag('Clear background', true),
                          ],
                        ),
                        const SizedBox(height: 20),

                                                 // Example images
                         Column(
                           children: [
                             Center(
                               child: _buildExampleImage('image/correct-img-1.webp', true),
                             ),
                             const SizedBox(height: 12),
                             Center(
                               child: _buildExampleImage('image/correct-img-2.webp', true),
                             ),
                             const SizedBox(height: 8),
                            const Text(
                              '✓ Good examples',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Avoid Examples Section
                                     Container(
                     width: double.infinity,
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: const Color(0xFFFEF2F2),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: const Color(0xFFFECACA)),
                     ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.close,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                                                         const Expanded(
                               child: Text(
                                 'Here\'s what your profile picture\nshould NOT include:',
                                 style: TextStyle(
                                   fontSize: 16,
                                   fontWeight: FontWeight.w600,
                                   color: Color(0xFF991B1B),
                                 ),
                               ),
                             ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildTag('Gurudev\'s image', false),
                            _buildTag('Group photos', false),
                            _buildTag('Celebrities', false),
                            _buildTag('Landscape/Nature', false),
                            _buildTag('Pets or with Pets', false),
                          ],
                        ),
                        const SizedBox(height: 20),

                                                 // Example images
                         Column(
                           children: [
                             Center(
                               child: _buildExampleImage('image/gurudev-wrong-img-1.webp', false),
                             ),
                             const SizedBox(height: 12),
                             Center(
                               child: _buildExampleImage('image/wrong-img-2.png', false),
                             ),
                             const SizedBox(height: 12),
                             Center(
                               child: _buildExampleImage('image/wrong-img-3.webp', false),
                             ),
                             const SizedBox(height: 8),
                            const Text(
                              '✗ Avoid these',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Why this matters section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Why this matters?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.only(left: 14),
                          child: Text(
                            'We use your profile photo to detect your presence in archived event photos. Only a clear headshot ensures proper matching.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF475569),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.only(left: 14),
                          child: Text(
                            'Still confused? Just click a selfie now and upload!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Guidelines
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF1F5F9), Color(0xFFF8FAFC)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Guidelines:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '\n Clear photos only • Max 2MB • \nJPEG/JPG/PNG',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(24),
            child: _hasReachedBottom
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onTryAgain?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Got it, I\'ll try again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: _scrollToBottom,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Scroll Down',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedBuilder(
                            animation: _bounceAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _bounceAnimation.value * 4),
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF64748B),
                                  size: 20,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, bool isCorrect) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCorrect ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.close,
            size: 12,
            color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isCorrect ? const Color(0xFF166534) : const Color(0xFF991B1B),
            ),
          ),
        ],
      ),
    );
  }

     Widget _buildExampleImage(String imagePath, bool isCorrect) {
     return Container(
       width: 80,
       height: 80,
      decoration: BoxDecoration(
        border: Border.all(
          color: isCorrect ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            Image.asset(
              imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
                                                                                                                                                                                                                                               errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      child: Icon(
                        isCorrect ? Icons.check_circle : Icons.close,
                        color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        size: 32,
                      ),
                    );
                  },
            ),
                                                                                                       Positioned(
                 bottom: 4,
                 right: 4,
                 child: Container(
                   width: 18,
                   height: 18,
                   decoration: BoxDecoration(
                     color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                     shape: BoxShape.circle,
                     border: Border.all(color: Colors.white, width: 1),
                   ),
                   child: Icon(
                     isCorrect ? Icons.check : Icons.close,
                     color: Colors.white,
                     size: 10,
                   ),
                 ),
               ),
          ],
        ),
      ),
    );
  }
}
