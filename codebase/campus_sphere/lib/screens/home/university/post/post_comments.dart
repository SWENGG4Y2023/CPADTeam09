import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_sphere/classes/comment.dart';
import 'package:campus_sphere/classes/student.dart';
import 'package:campus_sphere/classes/university.dart';
import 'package:campus_sphere/screens/within_screen_progress.dart';

class CommentsScreen extends StatefulWidget {
  // const CommentsScreen({super.key});

  CommentsScreen(
      {required this.commentDocId,
      required this.commenterProfileId,
      required this.commentByType});

  // comment doc id for setting up the stream for the doc, which is the post id passed from the post card widget
  String? commentDocId;

  // uni profile doc id for uni commenting
  // String? uniProfileDocId;

  // profile id for the commenter commenting to save with the comment in database
  String? commenterProfileId;

  // comment by type means comment by uni or student
  String commentByType;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  @override
  Widget build(BuildContext context) {
    // show inner comments screen content with comment object stream supplied to that screen
    return
        // Scaffold(
        //   backgroundColor: Colors.white,
        //   appBar: AppBar(
        //     title: Text('Comments'),
        //     backgroundColor: Colors.cyan[500],
        //   ),
        //   // scrollable body
        //   body:
        StreamProvider.value(
      value: Comment.id(docId: widget.commentDocId).getCommentsStream(),
      initialData: null,
      child: InnerCommentsScreen(
        commenterProfileId: widget.commenterProfileId,
        commentByType: widget.commentByType,
      ),
    );
  }
}

// inner comment screen
class InnerCommentsScreen extends StatefulWidget {
  // const InnerCommentsScreen({super.key});
  InnerCommentsScreen(
      {required this.commenterProfileId, required this.commentByType});

  // profile id passed from outer widget of the commenter
  String? commenterProfileId;

  // comment by type means comment by uni or student
  String commentByType;

  @override
  State<InnerCommentsScreen> createState() => _InnerCommentsScreenState();
}

class _InnerCommentsScreenState extends State<InnerCommentsScreen> {
  // post comments
  List<dynamic>? postComments; // list of type map of type string

  // comment text in the comment field
  String commentText = '';

  // form key
  // final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // comment by set check
  bool commentBySet = false;

  // controller for comment field to clear it
  final TextEditingController _textEditingController = TextEditingController();

  // function to clear comment field using controller
  void clearTextField() {
    _textEditingController.clear();
  }

  // time ago function to calculate and return how much time has passed since the comment posted
  String timeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo';
    } else {
      return '${(difference.inDays / 365).floor()}y';
    }
  }

  // converts comment at each index in post comments list to a widget
  // return a list of widgets for post comments
  List<Widget> _commentsWidgetList() {
    // list of widgets
    List<Widget> commentsWidgetsList = <Widget>[];

    // for loop (b/c for each not working below)
    for (int i = 0; i < postComments!.length; i++) {
      // calculate time ago for this comment
      final timeAgoTime =
          timeAgo(postComments![i]['comment_created_at'].toDate());
/*
      // commenter profile image path
      // based on comment by student/uni fetch image
      final profileImage = 
                postComments![i]['comment_by_type'] == "student" ? await StudentProfile.withId(profileDocId: postComments![i]['comment_by_profile_id']).getProfileImage() : await UniveristyProfile.withId(profileDocId: postComments![i]['comment_by_profile_id']).getProfileImagePath(); (cannot await here beacuse this is UI list which is required by the Ui below so need to fetch image seperately in setCommentByOnComment function set there in map and show image here)
                */

      // add widget in the list for the each comment
      commentsWidgetsList.add(Container(
        margin: EdgeInsets.symmetric(vertical: 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // commenter profile image
                // commenter name
                postComments![i]['comment_by_name'].length > 32
                    ? Text(
                        '${postComments![i]['comment_by_name'].substring(0, 32).trim()}...' ??
                            '',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )
                    : Text(
                        '${postComments![i]['comment_by_name'] ?? ''}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ],
            ),
            Container(
              padding: EdgeInsets.only(right: 10.0),
              child: Text(
                timeAgoTime,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 143, 143, 143)),
              ),
            ),
          ],
        ),
      ));
      // comment text widget
      commentsWidgetsList.add(Container(
        margin: EdgeInsets.only(bottom: 20.0),
        child: Text(
          '${postComments![i]['comment']}',
        ),
      ));

      // divider widget
      commentsWidgetsList.add(Divider(
        color: Colors.grey,
      ));
    }

    // sort by time posted (last comment in array will be latest)
    // commentsWidgetsList.sort((a,b)=> )

    // return list of widgets for the post
    return commentsWidgetsList;
  }

  // get, create and set new field i.e. comment by' name in comments list using the profile id with the comment
  _setCommentByOnComment() async {
    // for loop to iterate through every comment
    for (int i = 0; i < postComments!.length; i++) {
      // using the user type then get the name of the user through its respective collection
      if (postComments![i]['comment_by_type'] == 'university') {
        // change the profile id to uni name
        postComments![i]['comment_by_name'] = await UniveristyProfile.empty()
            .profileCollection
            // using profile id with the comment get the uni profile doc
            .doc(postComments![i]['comment_by_profile_id'])
            .get()
            // when the doc is fetched return the value at the name field in the doc ie. the name of uni
            .then((documentRef) => documentRef.get('name'));
      } else if (postComments![i]['comment_by_type'] == 'student') {
        // this creates a new pair in map, now set the name at the new key's value
        postComments![i]['comment_by_name'] = await StudentProfile.empty()
            .profileCollection
            // using profile id with the comment get the student profile doc
            .doc(postComments![i]['comment_by_profile_id'])
            .get()
            // when the doc is fetched return the value at the name field in the doc ie. the name of student
            .then((documentRef) => documentRef.get('name'));
      }
    }

    // now set the flag as true
    setState(() {
      commentBySet = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // consume the post comments stream here provided by the university_post_card widget (edit: cannot consume here because this widget is seperate from the widget tree of the university post card that is providing the stream)
    // final comment = Provider.of<Comment?>(context);

    // consume the post comments stream here provided by the Commentscreen widget
    final commentObj = Provider.of<Comment?>(
        context); // due tot this being final the value comment is not changed

    // print('commentObj ${commentObj!.comments!.length}');

    // check comments are present or not
    if (commentObj != null && postComments == null) {
      // setState(() {
      // print(comment.comments);
      postComments = commentObj.comments;
      // });
      // call to get the commnet by name if uni or student
      // _setCommentBy in list instead of profile id
      _setCommentByOnComment();
    }

    // widget tree
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Comments'),
        backgroundColor: Colors.cyan[500],
      ),
      bottomNavigationBar: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          height: 100,
          // constraints: BoxConstraints(
          //   minHeight: 100, // Minimum height for the input field
          //   maxHeight: 200, // Maximum height for the input field
          // ),
          child: BottomAppBar(
            surfaceTintColor: Colors.white,
            color: Colors.white,
            child: // comment input field section to comment
                // form container
                Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // comment field
                Container(
                  width: MediaQuery.of(context).size.width - 98,
                  // height: 200,
                  child: TextFormField(
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: Colors.black),
                    controller: _textEditingController,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0))),
                        hintText: widget.commentByType == 'student'
                            ? 'Comment as Student'
                            : 'Comment as University'),
                    onChanged: (value) {
                      setState(() {
                        commentText = value.trim();
                      });
                    },
                  ),
                ),
                // comment send button
                // based on comment var show button
                commentText == ''
                    ?
                    // cannot send button
                    MaterialButton(
                        // color: Colors.pink,
                        minWidth: 5,
                        onPressed: () {
                          // do nothing
                        },
                        child: Icon(Icons.send),
                        highlightColor: Colors.white,
                        highlightElevation: 0.0,
                        elevation: 0.0,
                      )
                    // can send button
                    : MaterialButton(
                        minWidth: 5,
                        onPressed: () async {
                          // get uni profile doc id
                          // setState(() {
                          // remove the comment_by_name key from map
                          // postComments = postComments!
                          //     .forEach((comment) =>
                          //         comment.remove('comment_by_name'))
                          //     .toList();

                          // clear comment text field
                          clearTextField();

                          // add the new comment in the list
                          postComments!.add({
                            'comment': commentText,
                            'comment_by_profile_id': widget.commenterProfileId,
                            'comment_by_type': widget.commentByType == 'student'
                                ? 'student'
                                : 'university',
                            'comment_created_at': Timestamp.now()
                          });

                          // set comment as empty to change button
                          setState(() {
                            commentText = '';
                            commentBySet =
                                false; // so that new comment is not shown until comment by is set on that comment
                          });

                          // set name on new comment
                          _setCommentByOnComment(); // new comment update is shown b/c set state is called inside this method and so post comments varaible chhages are reflected
                          // });

                          // print(postComments);
                          // call comment method
                          String? result = await Comment(
                                  docId: commentObj!.docId,
                                  comments: postComments)
                              .updateComments();

                          if (result == 'success') {
                            // show comment posted message
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   SnackBar(content: Text('Comment posted!')),
                            // );
                          } else if (result == null) {
                            // set latest commments color as red

                            // show error message
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   SnackBar(
                            //       content: Text(
                            //           'Something went wrong. Please try again later.')),
                            // );
                          }

                          // clear comment text field
                          // setState(() {
                          //   this.comment = '';
                          // });
                        },
                        child: Icon(Icons.send, color: Colors.cyan),
                      )
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // if comments are present in stream && comment done by is set on the comment then show comments
            if (postComments != null && commentBySet)
              Container(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // _commentsWidget()
                    //  children: [
                    //  postComments!.forEach((comment) =>
                    //     Text(comment['comment'] as String)
                    //   ).toList()
                    // ],
                    //  children: postComments!.forEach((comment) =>
                    //     Text(comment['comment'] as String)
                    //   ).toList()

                    // get the list of the comments converted into widgets
                    children: _commentsWidgetList(),
                  ))
            // show progress screen until comments are supplied in stream
            else
              WithinScreenProgress.withHeight(
                text: '',
                height: MediaQuery.of(context).size.height - 130,
              ),
            /*
            // comment input field section to comment
            // form container
            Container(
                height: 50.0,
                child: Container(
                  color: const Color.fromARGB(255, 209, 209, 209),
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // comment field
                      Container(
                        width: MediaQuery.of(context).size.width - 66,
                        child: TextFormField(
                          controller: _textEditingController,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10.0))),
                              hintText: widget.commentByType == 'student'
                                  ? 'Comment as Student'
                                  : 'Comment as University'),
                          onChanged: (value) {
                            setState(() {
                              commentText = value.trim();
                            });
                          },
                        ),
                      ),
                      // comment send button
                      // based on comment var show button
                      commentText == ''
                          ?
                          // cannot send button
                          MaterialButton(
                              // color: Colors.pink,
                              minWidth: 5,
                              onPressed: () {
                                // do nothing
                              },
                              child: Icon(Icons.send),
                            )
                          // can send button
                          : MaterialButton(
                              minWidth: 5,
                              onPressed: () async {
                                // get uni profile doc id
                                // setState(() {
                                // remove the comment_by_name key from map
                                // postComments = postComments!
                                //     .forEach((comment) =>
                                //         comment.remove('comment_by_name'))
                                //     .toList();
        
                                // clear comment text field
                                clearTextField();
        
                                // add the new comment in the list
                                postComments!.add({
                                  'comment': commentText,
                                  'comment_by_profile_id':
                                      widget.commenterProfileId,
                                  'comment_by_type':
                                      widget.commentByType == 'student'
                                          ? 'student'
                                          : 'university'
                                });
        
                                // set comment as empty to change button
                                setState(() {
                                  commentText = '';
                                });
        
                                // set name on new comment
                                _setCommentByOnComment(); // new comment update is shown b/c set state is called inside this method and so post comments varaible chhages are reflected
                                // });
        
                                // print(postComments);
                                // call comment method
                                String? result = await Comment(
                                        docId: commentObj!.docId,
                                        comments: postComments)
                                    .updateComments();
        
                                if (result == 'success') {
                                  // show comment posted message
                                  // ScaffoldMessenger.of(context).showSnackBar(
                                  //   SnackBar(content: Text('Comment posted!')),
                                  // );
                                } else if (result == null) {
                                  // set latest commments color as red
        
                                  // show error message
                                  // ScaffoldMessenger.of(context).showSnackBar(
                                  //   SnackBar(
                                  //       content: Text(
                                  //           'Something went wrong. Please try again later.')),
                                  // );
                                }
        
                                // clear comment text field
                                // setState(() {
                                //   this.comment = '';
                                // });
                              },
                              child: Icon(Icons.send, color: Colors.cyan),
                            )
                    ],
                  ),
                ))
                */
          ],
        ),
      ),
    );
  }
}
