import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/post_container.dart';
import '../../utils/db.dart';
import '../../utils/key.dart';
import '../../utils/parse.dart';
import '../../routes/feed/edit_feed.dart';
import '../../routes/read.dart';
import '../../models/models.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key, required this.feed});
  final Feed feed;
  @override
  State<FeedPage> createState() => FeedPageState();
}

class FeedPageState extends State<FeedPage> {
  List<Post> postList = [];
  bool onlyUnread = false;
  bool onlyFavorite = false;
  Map<String, dynamic> readPageInitData = {};

  Future<void> getPostList() async {
    List<Post> temp = await postsByFeedId(widget.feed.id!);
    setState(() {
      postList = temp;
    });
  }

  Future<void> getUnreadPostList() async {
    List<Post> temp = await unreadPostsByFeedId(widget.feed.id!);
    setState(() {
      postList = temp;
      onlyUnread = true;
      onlyFavorite = false;
    });
  }

  Future<void> getFavoritePostList() async {
    List<Post> temp = await favoritePostsByFeedId(widget.feed.id!);
    setState(() {
      postList = temp;
      onlyFavorite = true;
      onlyUnread = false;
    });
  }

  Future<void> getReadPageInitData() async {
    final Map<String, dynamic> temp = await getAllReadPageInitData();
    setState(() {
      readPageInitData = temp;
    });
  }

  @override
  void initState() {
    super.initState();
    getPostList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.feed.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry>[
                PopupMenuItem(
                  onTap: () async {
                    await markFeedPostsAsRead(widget.feed.id!);
                    if (onlyUnread) {
                      getUnreadPostList();
                    } else if (onlyFavorite) {
                      getFavoritePostList();
                    } else {
                      getPostList();
                    }
                  },
                  child: Text(
                    '全标已读',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                PopupMenuItem(
                  onTap: () async {
                    if (onlyUnread) {
                      await getPostList();
                      setState(() {
                        onlyUnread = false;
                      });
                    } else {
                      await getUnreadPostList();
                    }
                  },
                  child: Text(
                    onlyUnread ? '显示全部' : '只看未读',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                PopupMenuItem(
                  onTap: () async {
                    if (onlyFavorite) {
                      await getPostList();
                      setState(() {
                        onlyFavorite = false;
                      });
                    } else {
                      await getFavoritePostList();
                    }
                  },
                  child: Text(
                    onlyFavorite ? '显示全部' : '查看收藏',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  onTap: () {
                    Future.delayed(const Duration(seconds: 0), () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => EditFeedPage(feed: widget.feed),
                        ),
                      ).then((value) {
                        if (onlyUnread) {
                          getUnreadPostList();
                        } else if (onlyFavorite) {
                          getFavoritePostList();
                        } else {
                          getPostList();
                        }
                      });
                    });
                  },
                  child: Text(
                    '编辑订阅',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                // 删除订阅源
                PopupMenuItem(
                  onTap: () async {
                    await Future.delayed(const Duration(seconds: 0));
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('删除订阅'),
                          content: const Text('确定要删除该订阅吗？'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await deleteFeed(widget.feed.id!);
                                if (!mounted) return;
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text('确定'),
                            ),
                          ],
                        );
                      },
                    );
                    // await deleteFeed(widget.feed.id!);
                    // Future.delayed(const Duration(seconds: 0), () {
                    //   Navigator.pop(context);
                    // });
                  },
                  child: Text(
                    '删除订阅',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ];
            },
            elevation: 1,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          bool parseFeed = await parseFeedContent(widget.feed);
          if (onlyUnread) {
            getUnreadPostList();
          } else if (onlyFavorite) {
            getFavoritePostList();
          } else {
            getPostList();
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                parseFeed ? '更新成功' : '更新失败',
                textAlign: TextAlign.center,
              ),
              duration: const Duration(seconds: 1),
            ),
          );
          // 保证订阅源文章数不大于 feedMaxSaveCount
          final int feedMaxSaveCount = await getFeedMaxSaveCount();
          checkPostCountByFeed(widget.feed.id!, feedMaxSaveCount);
        },
        child: ListView.separated(
          itemCount: postList.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () async {
                if (postList[index].openType == 2) {
                  await launchUrl(
                    Uri.parse(postList[index].link),
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  getReadPageInitData();
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => ReadPage(
                        post: postList[index],
                        initData: readPageInitData,
                        fullText: widget.feed.fullText == 1,
                      ),
                    ),
                  ).then((value) {
                    if (onlyUnread) {
                      getUnreadPostList();
                    } else if (onlyFavorite) {
                      getFavoritePostList();
                    } else {
                      getPostList();
                    }
                  });
                }
                // 标记文章为已读
                if (postList[index].read == 0) {
                  markPostAsRead(postList[index].id!);
                }
              },
              child: PostContainer(post: postList[index]),
            );
          },
          separatorBuilder: (context, index) {
            return const Divider(
              thickness: 1,
            );
          },
        ),
      ),
    );
  }
}
