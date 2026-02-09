import 'package:flutter/material.dart';

import '../../../data/api/api_catalog.dart';
import '../../../resource/theme/dimens.dart';
import '../../../utils/responsive.dart';
import 'api_module_card.dart';

class ApiModules extends StatelessWidget {
  const ApiModules({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Modulos API",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              "$apiEndpointCount endpoints",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: defaultPadding),
        Responsive(
          mobile: ApiModuleGridView(
            crossAxisCount: size.width < 650 ? 1 : 2,
            childAspectRatio: size.width < 650 ? 1.6 : 1.4,
          ),
          tablet: const ApiModuleGridView(),
          desktop: ApiModuleGridView(
            childAspectRatio: size.width < 1400 ? 1.2 : 1.5,
          ),
        ),
      ],
    );
  }
}

class ApiModuleGridView extends StatelessWidget {
  const ApiModuleGridView({
    super.key,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.2,
  });

  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: apiModules.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: defaultPadding,
        mainAxisSpacing: defaultPadding,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) => ApiModuleCard(
        module: apiModules[index],
      ),
    );
  }
}
