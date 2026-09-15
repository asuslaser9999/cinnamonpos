import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pos_product_image_size.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../notifiers/pos_notifier.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'product_image.dart';

class PosProductCatalog extends StatelessWidget {
  const PosProductCatalog({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelectCategory,
    required this.searchOpen,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onToggleSearch,
    required this.isLoading,
    required this.products,
    required this.wide,
    required this.imageSize,
  });

  final List<ProductCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelectCategory;
  final bool searchOpen;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleSearch;
  final bool isLoading;
  final List<Product> products;
  final bool wide;
  final PosProductImageSize imageSize;

  int get _crossAxisCount => switch (imageSize) {
    PosProductImageSize.normal => wide ? 3 : 2,
    PosProductImageSize.compact => wide ? 4 : 3,
    PosProductImageSize.hidden => wide ? 4 : 3,
  };

  double get _aspectRatio => switch (imageSize) {
    PosProductImageSize.normal => wide ? 0.82 : 0.78,
    PosProductImageSize.compact => wide ? 0.92 : 0.88,
    PosProductImageSize.hidden => wide ? 1.55 : 1.45,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (searchOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Cari nama atau kategori produk',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isEmpty
                    ? IconButton(
                        onPressed: onToggleSearch,
                        icon: const Icon(Icons.close),
                      )
                    : IconButton(
                        onPressed: () => onSearchChanged(''),
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: onSearchChanged,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: searchOpen ? 'Tutup pencarian' : 'Cari produk',
                onPressed: onToggleSearch,
                icon: Icon(searchOpen ? Icons.close : Icons.search),
              ),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('Semua'),
                          selected: selectedCategoryId == null,
                          onSelected: (_) => onSelectCategory(null),
                        ),
                      ),
                      ...categories.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c.name),
                            selected: selectedCategoryId == c.id,
                            onSelected: (_) => onSelectCategory(c.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : products.isEmpty
              ? Center(
                  child: Text(
                    searchQuery.trim().isEmpty
                        ? 'Belum ada produk aktif.'
                        : 'Produk tidak ditemukan.',
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount,
                    childAspectRatio: _aspectRatio,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Selector<PosNotifier, bool>(
                      selector: (_, pos) => pos.lines.any(
                        (line) => line.product.id == product.id,
                      ),
                      builder: (context, inCart, _) {
                        return _ProductTile(
                          product: product,
                          inCart: inCart,
                          imageSize: imageSize,
                          onTap: () =>
                              context.read<PosNotifier>().addProduct(product),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.inCart,
    required this.imageSize,
    required this.onTap,
  });

  final Product product;
  final bool inCart;
  final PosProductImageSize imageSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hideImage = imageSize == PosProductImageSize.hidden;
    final compact = imageSize == PosProductImageSize.compact;

    final details = Padding(
      padding: EdgeInsets.fromLTRB(
        compact || hideImage ? 8 : 10,
        hideImage ? 8 : 6,
        compact || hideImage ? 8 : 10,
        hideImage ? 8 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: hideImage
            ? MainAxisAlignment.center
            : MainAxisAlignment.end,
        children: [
          if (!hideImage)
            Text(
              product.categoryName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: compact || hideImage ? 13 : 14,
            ),
          ),
          Text(
            CurrencyFormatter.format(product.sellingPrice),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: compact || hideImage ? 12 : 13,
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: AppShapes.borderMedium,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: AppShapes.borderMedium,
          border: Border.all(
            color: inCart ? scheme.primary : scheme.outlineVariant,
            width: inCart ? 1.6 : 1,
          ),
        ),
        child: hideImage
            ? details
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: compact ? 3 : 5,
                    child: ProductImage(
                      imageUrl: product.imageUrl,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppShapes.medium),
                      ),
                    ),
                  ),
                  details,
                ],
              ),
      ),
    );
  }
}
