import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/post_container.dart';
import '../../utils/db.dart';
import '../utils/parse.dart';
import '../../utils/key.dart';
import '../../routes/feed/add_feed.dart';
import '../../routes/feed/feed.dart';
import '../../routes/read.dart';
import '../../routes/setting/set.dart';
import '../../models/models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  Map<String, List<Feed>> feedListGroupByCategory = {};
  List<Post> postList = [];
  bool onlyUnread = false;
  bool onlyFavorite = false;
  Map<String, dynamic> readPageInitData = {};
  Map<int, int> unreadCount = {};

  Future<void> getFeedList() async {
    Map<String, List<Feed>> temp = await feedsGroupByCategory();
    setState(() {
      feedListGroupByCategory = temp;
    });
  }

  Future<void> getPostList() async {
    List<Post> temp = await posts();
    setState(() {
      postList = temp;
    });
  }

  Future<void> getUnreadPost() async {
    List<Post> temp = await unreadPosts();
    setState(() {
      postList = temp;
      onlyUnread = true;
      onlyFavorite = false;
    });
  }

  Future<void> getFavoritePost() async {
    List<Post> temp = await favoritePosts();
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

  Future<void> getUnreadCount() async {
    final Map<int, int> temp = await unreadPostCount();
    setState(() {
      unreadCount = temp;
    });
  }

  @override
  void initState() {
    super.initState();
    getFeedList();
    getPostList();
    getUnreadCount();
    getReadPageInitData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '??????',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry>[
                PopupMenuItem(
                  onTap: () async {
                    await markAllPostsAsRead();
                    if (onlyUnread) {
                      getUnreadPost();
                    } else if (onlyFavorite) {
                      getFavoritePost();
                    } else {
                      getPostList();
                    }
                    getUnreadCount();
                  },
                  child: Text(
                    '????????????',
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
                      await getUnreadPost();
                    }
                  },
                  child: Text(
                    onlyUnread ? '????????????' : '????????????',
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
                      await getFavoritePost();
                    }
                  },
                  child: Text(
                    onlyFavorite ? '????????????' : '????????????',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  onTap: () {
                    // ????????????????????????????????????????????????????????????
                    Future.delayed(const Duration(seconds: 0), () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const AddFeedPage(),
                        ),
                      ).then((value) => getFeedList());
                    });
                  },
                  child: Text(
                    '????????????',
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
                          builder: (context) => const SetPage(),
                        ),
                      ).then((value) {
                        getFeedList();
                        if (onlyUnread) {
                          getUnreadPost();
                        } else if (onlyFavorite) {
                          getFavoritePost();
                        } else {
                          getPostList();
                        }
                        getReadPageInitData();
                      });
                    });
                  },
                  child: Text(
                    '??????',
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
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: ListView.builder(
            itemCount: feedListGroupByCategory.length,
            itemBuilder: (BuildContext context, int index) {
              return ExpansionTile(
                controlAffinity: ListTileControlAffinity.platform,
                title: Text(
                  feedListGroupByCategory.keys.toList()[index],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                children: [
                  Column(
                    children: [
                      for (Feed feed
                          in feedListGroupByCategory.values.toList()[index])
                        ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.fromLTRB(40, 0, 20, 0),
                          title: Text(
                            feed.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          trailing: Text(
                            unreadCount[feed.id] == null
                                ? ''
                                : unreadCount[feed.id].toString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          onTap: () {
                            if (!mounted) return;
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => FeedPage(feed: feed),
                              ),
                            ).then((value) {
                              getFeedList();
                              getUnreadCount();
                              if (onlyUnread) {
                                getUnreadPost();
                              } else if (onlyFavorite) {
                                getFavoritePost();
                              } else {
                                getPostList();
                              }
                            });
                          },
                        ),
                    ],
                  )
                ],
              );
            },
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          List<Feed> feedList = await feeds();
          int failCount = 0;
          await Future.wait(
            feedList.map(
              (e) => parseFeedContent(e).then(
                (value) async {
                  if (value) {
                    if (onlyUnread) {
                      await getUnreadPost();
                    } else if (!onlyFavorite) {
                      await getPostList();
                    }
                    await getUnreadCount();
                  } else {
                    failCount++;
                  }
                },
              ),
            ),
          );
          if (failCount > 0) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '???????????? $failCount ????????????',
                  textAlign: TextAlign.center,
                ),
                duration: const Duration(seconds: 1),
              ),
            );
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '????????????',
                  textAlign: TextAlign.center,
                ),
                duration: Duration(seconds: 1),
              ),
            );
          }
          // ???????????????????????????????????? feedMaxSaveCount
          final int feedMaxSaveCount = await getFeedMaxSaveCount();
          checkPostCount(feedMaxSaveCount);
        },
        child: ListView.separated(
          cacheExtent: 30, // ?????????
          itemCount: postList.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              // ?????? openType ????????????
              onTap: () async {
                if (postList[index].openType == 2) {
                  // ?????????????????????
                  await launchUrl(
                    Uri.parse(postList[index].link),
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  // ??????????????????????????? or ?????????
                  final bool fullText =
                      await feedFullText(postList[index].feedId) == 1;
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => ReadPage(
                        post: postList[index],
                        initData: readPageInitData,
                        fullText: fullText,
                      ),
                    ),
                  ).then((value) {
                    // ???????????????????????????
                    if (onlyUnread) {
                      getUnreadPost();
                    } else if (onlyFavorite) {
                      getFavoritePost();
                    } else {
                      getPostList();
                    }
                    getUnreadCount();
                  });
                }
                // ?????????????????????
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
