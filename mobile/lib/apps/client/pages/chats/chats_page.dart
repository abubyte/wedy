import 'package:flutter/material.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/shared/widgets/empty_state.dart';

class ClientChatsPage extends StatelessWidget {
  const ClientChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingXL),
          child: WedyEmptyState(
            title: 'Tez orada ishga tushadi!',
            subtitle:
                'Yangi chat funksiyasi yordamida sotuvchilar bilan to‘g‘ridan-to‘g‘ri muloqot qilishingiz mumkin bo‘ladi. Bronlar, savollar va buyurtmalar endi bir joyda! Ushbu  bo‘lim ustida ish olib borilmoqda va yaqin oylarda ishga tushiriladi. Biz sizga eng qulay va tezkor aloqa tizimini taqdim etamiz!',
          ),
        ),
      ),
    );
  }
}
