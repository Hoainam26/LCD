import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/news_item.dart';
import '../services/app_state_service.dart';
import '../widgets/news_card.dart';
import 'news_detail_screen.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AppStateService>(context, listen: false).refreshNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Tin tức & Thông báo'),
        backgroundColor: AppColors.surfaceColor,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Consumer<AppStateService>(
        builder: (context, appState, _) {
          if (appState.isLoadingNews) {
            return const Center(child: CircularProgressIndicator());
          }

          final visibleNews = appState.news
              .where((item) => item.status == 'published')
              .toList()
            ..sort(compareNewsItems);

          if (visibleNews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.newspaper, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có tin tức nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: appState.refreshNews,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visibleNews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final news = visibleNews[index];
                return NewsCardGrid(
                  news: news,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewsDetailScreen(news: news),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
