import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cook_assistant/ui/theme/color.dart';
import 'package:cook_assistant/ui/theme/text_styles.dart';
import 'package:cook_assistant/widgets/button/primary_button.dart';
import 'package:cook_assistant/widgets/dialog.dart';
import 'package:intl/intl.dart';
import 'package:cook_assistant/resource/config.dart';

class RecipeDetailPage extends StatefulWidget {
  final bool registered;
  final int recipeId;
  final Map<String, dynamic>? recipeDetails;
  final String? userDiet; // null 가능
  final String? recipeName; // null 가능
  final String? imageType;

  RecipeDetailPage({
    Key? key,
    required this.registered,
    required this.recipeId,
    this.recipeDetails,
    this.userDiet,
    this.recipeName,
    this.imageType,
  }) : super(key: key);

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  Map<String, dynamic> recipeDetails = {};
  bool isLoading = true;
  bool isError = false;
  bool isLiked = false;
  int userId = 0;

  final String defaultAuthorId = 'defaultNickName';
  final String defaultRecipeName = 'defaultRecipeName123';
  final String defaultDietType = 'defaultDietType';

  final String defaultContent = '''
tmptmptmp
t
t
t
t
1. 냄비에 들기름을 두르고 다진 대파와 마늘을 볶아 향을 낸 후 양파를 넣어 볶습니다.
2. 양파가 투명해질 때까지 볶은 후 고춧가루를 넣고 빨간 기름이 돌도록 볶아줍니다.
3. 된장을 넣고 잘 섞어줍니다.
4. 신김치를 넣고 볶아줍니다.
5. 물을 넣고 국물이 끓어오르면 중간 불로 줄여 끓여줍니다.
6. 국물이 끓어오르면 소금으로 간을 맞추고 남은 김치찌개 국물을 추가해 깊은 맛을 더해줍니다.
7. 김치찌개가 끓어오르면 불을 끄고 다진 대파를 고루 뿌려줍니다.
8. 그릇에 담으면 완성입니다.
''';

  @override
  void initState() {
    super.initState();
    if (widget.recipeId == 0 && widget.recipeDetails != null) {
      setState(() {
        recipeDetails = widget.recipeDetails!;
        isLoading = false;
      });
    } else if (widget.recipeId != 0) {
      fetchUserDetails();
    }
    print("User Diet: ${widget.userDiet}");
    print("Recipe Name: ${widget.recipeName}");
  }

  Future<void> fetchUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');
    if (accessToken != null && accessToken.isNotEmpty && accessToken != 'guest') {
      try {
        var url = Uri.parse('${Config.baseUrl}/api/v1/users/myPage');
        var response = await http.get(url, headers: {
          'Authorization': 'Bearer $accessToken',
        });

        print('Response Status Code: ${response.statusCode}');
        print('Response Body: ${utf8.decode(response.bodyBytes)}');

        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
          setState(() {
            userId = jsonResponse['data']['userId'];
          });
          fetchRecipeDetails(accessToken);
        } else {
          setState(() {
            isError = true;
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          isError = true;
          isLoading = false;
        });
        print('Error fetching user details: $e');
      }
    } else {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  Future<void> fetchRecipeDetails(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/recipes/${widget.recipeId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        setState(() {
          recipeDetails = json.decode(utf8.decode(response.bodyBytes))['data'];
          isLoading = false;
          isLiked = recipeDetails['isLikedByUser'] ?? false;
        });
      } else {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }

    print('Fetched Recipe Details: $recipeDetails');
    print('Recipe ID: ${widget.recipeId}');
    print('Content: ${recipeDetails['content']}');
  }

  String formatDate(List<dynamic> dateList) {
    try {
      final DateTime dateTime = DateTime(dateList[0], dateList[1], dateList[2], dateList[3], dateList[4], dateList[5], dateList[6]);
      final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');
      return formatter.format(dateTime);
    } catch (e) {
      return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    }
  }

  Future<void> likeRecipe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.post(
      Uri.parse('${Config.baseUrl}/api/v1/likes/new'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'userId': userId,
        'recipeId': widget.recipeId,
      }),
    );

    if (response.statusCode == 201) {
      setState(() {
        isLiked = true;
      });
      CustomAlertDialog.showCustomDialog(
        context: context,
        title: '레시피 좋아요',
        content: '레시피에 좋아요를 눌렀습니다.',
        cancelButtonText: '',
        confirmButtonText: '확인',
        onConfirm: () {},
      );
    } else {
      CustomAlertDialog.showCustomDialog(
        context: context,
        title: '좋아요 실패',
        content: '레시피 좋아요에 실패하였습니다. 상태 코드: ${response.statusCode}',
        cancelButtonText: '',
        confirmButtonText: '확인',
        onConfirm: () {},
      );
    }
  }

  Future<void> unlikeRecipe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/api/v1/likes/delete'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'userId': userId,
        'recipeId': widget.recipeId,
      }),
    );

    if (response.statusCode == 204) {
      setState(() {
        isLiked = false;
      });
      CustomAlertDialog.showCustomDialog(
        context: context,
        title: '좋아요 취소',
        content: '레시피 좋아요를 취소하였습니다.',
        cancelButtonText: '',
        confirmButtonText: '확인',
        onConfirm: () {},
      );
    } else {
      CustomAlertDialog.showCustomDialog(
        context: context,
        title: '좋아요 취소 실패',
        content: '레시피 좋아요 취소에 실패하였습니다. 상태 코드: ${response.statusCode}',
        cancelButtonText: '',
        confirmButtonText: '확인',
        onConfirm: () {},
      );
    }
  }

  Future<void> deleteRecipe(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/api/v1/recipes/delete'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'recipeId': widget.recipeId,
      }),
    );

    if (response.statusCode == 200) {
      CustomAlertDialog.showCustomDialog(
        context: context,
        title: '삭제 성공',
        content: '레시피가 성공적으로 삭제되었습니다.',
        cancelButtonText: '',
        confirmButtonText: '확인',
        onConfirm: () {
          Navigator.of(context).pop();
        },
      );
    } else {
      CustomAlertDialog.showCustomDialog(
        context: context,
        title: '삭제 실패',
        content: '레시피 삭제에 실패했습니다. 상태 코드: ${response.statusCode}',
        cancelButtonText: '',
        confirmButtonText: '확인',
        onConfirm: () {},
      );
    }
  }

  Future<void> registerRecipe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');
    print('accessToken: $accessToken');

    final Map<String, dynamic> requestData = {
      'name': widget.recipeName ?? defaultRecipeName,
      'content': recipeDetails.containsKey('content') ? recipeDetails['content'] : defaultContent,
      'imageURL': widget.imageType,
    };

    print('Request Data: $requestData');

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/recipes/new'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestData),
      );

      var decodedResponse = utf8.decode(response.bodyBytes);
      var jsonResponse = jsonDecode(decodedResponse);

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: $decodedResponse');

      if (response.statusCode == 200) {
        CustomAlertDialog.showCustomDialog(
          context: context,
          title: '등록 성공',
          content: '레시피가 커뮤니티에 등록되었습니다.',
          cancelButtonText: '',
          confirmButtonText: '확인',
          onConfirm: () {
            Navigator.of(context).pop();
          },
        );
      } else {
        CustomAlertDialog.showCustomDialog(
          context: context,
          title: '등록 실패',
          content: '레시피 등록에 실패했습니다. 상태 코드: ${jsonResponse['statusCode']}',
          cancelButtonText: '',
          confirmButtonText: '확인',
          onConfirm: () {},
        );
      }
    } catch (e) {
      print('Exception: $e');
      CustomAlertDialog.showCustomDialog(
        context: context,
        title: '등록 실패',
        content: '레시피 등록에 실패했습니다. 예외: $e',
        cancelButtonText: '',
        confirmButtonText: '확인',
        onConfirm: () {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '레시피 상세정보',
          style: AppTextStyles.headingH4.copyWith(color: AppColors.neutralDarkDarkest),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.neutralDarkDarkest),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: Colors.white,
              shadowColor: Colors.transparent,
            ),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppColors.neutralDarkDarkest),
              onSelected: (String value) {
                if (value == 'delete') {
                  CustomAlertDialog.showCustomDialog(
                    context: context,
                    title: '레시피 삭제',
                    content: '정말로 레시피를 삭제하시겠습니까?',
                    cancelButtonText: '취소',
                    confirmButtonText: '삭제',
                    onConfirm: () {
                      Navigator.of(context).pop();
                      deleteRecipe(context);
                    },
                  );
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      '삭제하기',
                      style: AppTextStyles.bodyM.copyWith(color: AppColors.neutralDarkDarkest),
                    ),
                  ),
                ];
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  widget.imageType ?? recipeDetails['imageURL'] ?? 'assets/images/mushroom.jpg',
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.recipeName ?? recipeDetails['name'] ?? defaultRecipeName, // 레시피 이름 출력
                      style: AppTextStyles.headingH2.copyWith(color: AppColors.neutralDarkDarkest),
                    ),
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : AppColors.neutralDarkDarkest,
                      ),
                      onPressed: () {
                        if (isLiked) {
                          unlikeRecipe();
                        } else {
                          likeRecipe();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  widget.userDiet ?? recipeDetails['dietType'] ?? defaultDietType, // 사용자 식단 출력
                  style: AppTextStyles.bodyL.copyWith(color: AppColors.neutralDarkDarkest),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      recipeDetails['authorId'] ?? defaultAuthorId,
                      style: AppTextStyles.bodyS.copyWith(color: AppColors.neutralDarkLight),
                    ),
                    Text(
                      recipeDetails['createdAt'] != null
                          ? formatDate(recipeDetails['createdAt'])
                          : DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()), // 현재 날짜 출력
                      style: AppTextStyles.bodyS.copyWith(color: AppColors.neutralDarkLight),
                    ),
                  ],
                ),
                const SizedBox(height: 32.0),
                Text(
                  '조리 방법',
                  style: AppTextStyles.headingH5.copyWith(color: AppColors.neutralDarkDarkest),
                ),
                Text(
                  recipeDetails['content'] ?? defaultContent,
                  style: AppTextStyles.bodyS.copyWith(color: AppColors.neutralDarkDarkest),
                ),
                const SizedBox(height: 100.0),
              ],
            ),
          ),
          if (!widget.registered)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: PrimaryButton(
                  text: '커뮤니티에 등록하기',
                  onPressed: registerRecipe,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
