import 'package:flutter/material.dart';

// Simple Carousel Widget (replacement for carousel_slider)
class SimpleCarousel extends StatefulWidget {
  final List<Widget> items;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Function(int) onPageChanged;

  const SimpleCarousel({
    super.key,
    required this.items,
    required this.height,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 4),
    required this.onPageChanged,
  });

  @override
  State<SimpleCarousel> createState() => _SimpleCarouselState();
}

class _SimpleCarouselState extends State<SimpleCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.autoPlay) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    Future.delayed(widget.autoPlayInterval, () {
      if (mounted && _pageController.hasClients) {
        try {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } catch (e) {
          // Ignore if controller is disposed
        }
        _startAutoPlay();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index % widget.items.length;
          });
          widget.onPageChanged(_currentIndex);
        },
        itemBuilder: (context, index) {
          return widget.items[index % widget.items.length];
        },
      ),
    );
  }
}
