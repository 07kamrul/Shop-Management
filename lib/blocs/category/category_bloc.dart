import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/category_service.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc() : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
  }

  void _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoriesLoadInProgress());
    try {
      final categories = await CategoryService.getCategories();
      emit(CategoriesLoadSuccess(categories: categories));
    } catch (e) {
      emit(CategoriesLoadFailure(error: e.toString()));
    }
  }

  Future<void> _onAddCategory(
    AddCategory event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryOperationInProgress());
    try {
      await CategoryService.createCategory(
        name: event.category['name'],
        parentCategoryId: event.category['parentCategoryId'],
        description: event.category['description'],
        profitMarginTarget: event.category['profitMarginTarget'],
      );

      emit(CategoryOperationSuccess());
    } catch (e) {
      emit(CategoryOperationFailure(error: e.toString()));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryOperationInProgress());
    try {
      await CategoryService.updateCategory(
        id: event.category['id'],
        name: event.category['name'],
        parentCategoryId: event.category['parentCategoryId'],
        description: event.category['description'],
        profitMarginTarget: event.category['profitMarginTarget'],
      );

      emit(CategoryOperationSuccess());
    } catch (e) {
      emit(CategoryOperationFailure(error: e.toString()));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryOperationInProgress());
    try {
      await CategoryService.deleteCategory(event.categoryId);

      emit(CategoryOperationSuccess());

      // Reload categories after deletion
      add(const LoadCategories());
    } catch (e) {
      emit(CategoryOperationFailure(error: e.toString()));
    }
  }
}
