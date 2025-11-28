import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/features/profile/domain/entities/city_entity.dart';
import 'package:ketroy_app/features/profile/presentation/bloc/profile_bloc.dart';

class CitySelectionPage extends StatefulWidget {
  const CitySelectionPage({super.key});

  @override
  State<CitySelectionPage> createState() => _CitySelectionPageState();
}

class _CitySelectionPageState extends State<CitySelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCity = 'Усть-Каменогорск';

  @override
  void initState() {
    context.read<ProfileBloc>().add(GetCityListFetch());
    super.initState();
  }

  List<CityEntity> getFilteredCities(List<CityEntity> cities) {
    if (_searchController.text.isEmpty) {
      return cities;
    }
    return cities
        .where((city) => city.name
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Text(
          'Профиль',
          style: TextStyle(fontSize: 17.sp),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {},
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    fillColor: Colors.black,
                                    hintText: 'Найти город',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Icon(
                              //   Icons.mic,
                              //   color: Colors.grey[400],
                              //   size: 20,
                              // ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Cities List
                        Expanded(
                          child: _buildCitiesList(state),
                        ),

                        // // Bottom Text
                        // Padding(
                        //   padding:
                        //       EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        //   child: Text(
                        //     'Вы можете выбрать из более, чем 3 000 населенных пунктов по всей республике Казахстан.',
                        //     style: TextStyle(
                        //       fontSize: 14,
                        //       color: Colors.grey[500],
                        //       height: 1.4,
                        //     ),
                        //     textAlign: TextAlign.left,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCitiesList(ProfileState state) {
    // Получаем список городов из состояния
    List<CityEntity> cities = [];
    if (state.cityList.isNotEmpty) {
      cities = state.cityList;
    }

    // Если список пустой, показываем сообщение
    if (cities.isEmpty) {
      return Center(
        child: Text(
          'Список городов пуст',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    // Фильтруем города
    List<CityEntity> filteredCities = getFilteredCities(cities);

    // Если после фильтрации ничего не найдено
    if (filteredCities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Город не найден',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить запрос',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Отображаем список городов
    return ListView.separated(
      itemCount: filteredCities.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.grey[300],
      ),
      itemBuilder: (context, index) {
        String city = filteredCities[index].name;
        bool isSelected = city == _selectedCity;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedCity = city;
            });

            // Можно также вернуться на предыдущую страницу
            Navigator.pop(context, city);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                if (isSelected) ...[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    city,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
