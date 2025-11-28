<template>
  <section class="reviews-page">
    <!-- Заголовок и статистика -->
    <div class="reviews-page__header">
      <div class="reviews-page__stats">
        <div class="reviews-page__stat-card">
          <div class="reviews-page__stat-icon reviews-page__stat-icon--total">
            <Icon name="mdi:message-text-outline" />
          </div>
          <div class="reviews-page__stat-info">
            <span class="reviews-page__stat-value">{{ reviews.length }}</span>
            <span class="reviews-page__stat-label">Всего отзывов</span>
          </div>
        </div>
        <div class="reviews-page__stat-card">
          <div class="reviews-page__stat-icon reviews-page__stat-icon--rating">
            <Icon name="mdi:star" />
          </div>
          <div class="reviews-page__stat-info">
            <span class="reviews-page__stat-value">{{ averageRating }}</span>
            <span class="reviews-page__stat-label">Средний рейтинг</span>
          </div>
        </div>
        <div class="reviews-page__stat-card">
          <div class="reviews-page__stat-icon reviews-page__stat-icon--shops">
            <Icon name="mdi:store-outline" />
          </div>
          <div class="reviews-page__stat-info">
            <span class="reviews-page__stat-value">{{ uniqueShops }}</span>
            <span class="reviews-page__stat-label">Магазинов с отзывами</span>
          </div>
        </div>
        <div class="reviews-page__stat-card">
          <div class="reviews-page__stat-icon reviews-page__stat-icon--edited">
            <Icon name="mdi:pencil" />
          </div>
          <div class="reviews-page__stat-info">
            <span class="reviews-page__stat-value">{{ editedCount }}</span>
            <span class="reviews-page__stat-label">Изменённых отзывов</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Фильтры -->
    <div class="reviews-page__filters">
      <v-text-field
        v-model="searchQuery"
        placeholder="Поиск по отзывам..."
        prepend-inner-icon="mdi-magnify"
        variant="outlined"
        density="compact"
        hide-details
        class="reviews-page__search"
      />
      <v-select
        v-model="filterRating"
        :items="ratingOptions"
        item-title="label"
        item-value="value"
        placeholder="Все рейтинги"
        variant="outlined"
        density="compact"
        hide-details
        clearable
        class="reviews-page__filter"
      />
      <v-select
        v-model="filterShop"
        :items="shopOptions"
        item-title="name"
        item-value="id"
        placeholder="Все магазины"
        variant="outlined"
        density="compact"
        hide-details
        clearable
        class="reviews-page__filter"
      />
      <v-select
        v-model="filterEdited"
        :items="editedOptions"
        item-title="label"
        item-value="value"
        placeholder="Все отзывы"
        variant="outlined"
        density="compact"
        hide-details
        clearable
        class="reviews-page__filter"
      />
    </div>

    <!-- Сетка отзывов -->
    <div v-if="loading" class="reviews-page__loading">
      <v-progress-circular indeterminate color="var(--color-accent)" :size="48" :width="4" />
      <span>Загрузка отзывов...</span>
    </div>

    <div v-else-if="filteredReviews.length === 0" class="reviews-page__empty">
      <Icon name="mdi:message-off-outline" class="reviews-page__empty-icon" />
      <p class="reviews-page__empty-title">Отзывов пока нет</p>
      <p class="reviews-page__empty-text">Когда пользователи оставят отзывы, они появятся здесь</p>
    </div>

    <div v-else class="reviews-page__grid">
      <transition-group name="review-card" tag="div" class="reviews-page__cards">
        <div v-for="review in paginatedReviews" :key="review.id" class="review-card">
          <!-- Шапка карточки с магазином -->
          <div class="review-card__header">
            <div class="review-card__shop">
              <div class="review-card__shop-avatar">
                <img 
                  v-if="review.shop?.image_url" 
                  :src="review.shop.image_url" 
                  :alt="review.shop?.name"
                  class="review-card__shop-image"
                />
                <Icon v-else name="mdi:store" class="review-card__shop-placeholder" />
              </div>
              <div class="review-card__shop-info">
                <span class="review-card__shop-name">{{ review.shop?.name || 'Магазин' }}</span>
                <span class="review-card__shop-city">{{ review.shop?.city || '—' }}</span>
              </div>
            </div>
            <button class="review-card__delete" @click="confirmDelete(review)">
              <Icon name="mdi:delete-outline" />
            </button>
          </div>

          <!-- Рейтинг -->
          <div class="review-card__rating">
            <div class="review-card__stars">
              <template v-for="star in 5" :key="star">
                <Icon 
                  :name="getStarIcon(star, review.rating)" 
                  class="review-card__star"
                  :class="{ 'review-card__star--filled': star <= Math.floor(review.rating) }"
                />
              </template>
            </div>
            <span class="review-card__rating-value">{{ formatRating(review.rating) }}</span>
          </div>

          <!-- Текст отзыва -->
          <p class="review-card__text">{{ review.review }}</p>

          <!-- Футер с информацией о пользователе -->
          <div class="review-card__footer">
            <div class="review-card__user">
              <v-avatar size="32" class="review-card__user-avatar">
                <img v-if="review.user?.image?.path" :src="fileUrlValidator(review.user.image.path)" alt="User" />
                <Icon v-else name="mdi:account" />
              </v-avatar>
              <div class="review-card__user-info">
                <span class="review-card__user-name">{{ review.user?.name || 'Пользователь' }}</span>
                <span class="review-card__date">{{ formatDate(review.updated_at || review.created_at) }}</span>
              </div>
            </div>
            <!-- Пометка "Изменён" -->
            <div v-if="review.is_edited" class="review-card__edited-badge">
              <Icon name="mdi:pencil" />
              <span>Изменён</span>
            </div>
          </div>
        </div>
      </transition-group>
    </div>

    <!-- Пагинация -->
    <div v-if="filteredReviews.length > perPage" class="reviews-page__pagination">
      <v-pagination
        v-model="page"
        :length="totalPages"
        rounded="lg"
        :total-visible="5"
      />
    </div>

    <!-- Диалог подтверждения удаления -->
    <v-dialog v-model="deleteDialog" max-width="400">
      <v-card class="reviews-page__delete-dialog">
        <v-card-title class="reviews-page__delete-title">
          <Icon name="mdi:alert-circle-outline" />
          Удалить отзыв?
        </v-card-title>
        <v-card-text class="reviews-page__delete-text">
          Вы уверены, что хотите удалить этот отзыв? Это действие нельзя отменить.
        </v-card-text>
        <v-card-actions class="reviews-page__delete-actions">
          <v-btn variant="text" @click="deleteDialog = false">Отмена</v-btn>
          <v-btn color="error" variant="flat" :loading="deleting" @click="deleteReview">
            Удалить
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </section>
</template>

<script setup lang="ts">
const reviews = ref<any[]>([]);
const loading = ref(true);
const searchQuery = ref('');
const filterRating = ref<number | null>(null);
const filterShop = ref<number | null>(null);
const page = ref(1);
const perPage = 12;
const deleteDialog = ref(false);
const reviewToDelete = ref<any>(null);
const deleting = ref(false);

const ratingOptions = [
  { label: '5 звёзд', value: 5 },
  { label: '4+ звёзд', value: 4 },
  { label: '3+ звёзд', value: 3 },
  { label: '2+ звёзд', value: 2 },
  { label: '1+ звезда', value: 1 },
];

const filterEdited = ref<boolean | null>(null);
const editedOptions = [
  { label: 'Изменённые', value: true },
  { label: 'Новые', value: false },
];

const shopOptions = computed(() => {
  const shops = reviews.value
    .filter(r => r.shop)
    .map(r => r.shop)
    .filter((shop, index, self) => 
      index === self.findIndex(s => s.id === shop.id)
    );
  return shops;
});

const averageRating = computed(() => {
  if (reviews.value.length === 0) return '0.0';
  const sum = reviews.value.reduce((acc, r) => acc + (r.rating || 0), 0);
  return (sum / reviews.value.length).toFixed(1);
});

const uniqueShops = computed(() => {
  return new Set(reviews.value.map(r => r.shop_id)).size;
});

const editedCount = computed(() => {
  return reviews.value.filter(r => r.is_edited).length;
});

const filteredReviews = computed(() => {
  return reviews.value.filter(review => {
    const matchesSearch = !searchQuery.value || 
      review.review?.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      review.shop?.name?.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      review.user?.name?.toLowerCase().includes(searchQuery.value.toLowerCase());
    
    const matchesRating = !filterRating.value || review.rating >= filterRating.value;
    const matchesShop = !filterShop.value || review.shop_id === filterShop.value;
    const matchesEdited = filterEdited.value === null || review.is_edited === filterEdited.value;
    
    return matchesSearch && matchesRating && matchesShop && matchesEdited;
  });
});

const totalPages = computed(() => Math.ceil(filteredReviews.value.length / perPage));

const paginatedReviews = computed(() => {
  const start = (page.value - 1) * perPage;
  return filteredReviews.value.slice(start, start + perPage);
});

const getStarIcon = (star: number, rating: number) => {
  if (star <= Math.floor(rating)) {
    return 'mdi:star';
  } else if (star === Math.ceil(rating) && rating % 1 !== 0) {
    return 'mdi:star-half-full';
  }
  return 'mdi:star-outline';
};

const formatRating = (rating: number | null) => {
  if (!rating) return '0.0';
  return Number(rating).toFixed(1);
};

const formatDate = (dateStr: string) => {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  return date.toLocaleDateString('ru-RU', { 
    day: 'numeric', 
    month: 'short', 
    year: 'numeric' 
  });
};

const confirmDelete = (review: any) => {
  reviewToDelete.value = review;
  deleteDialog.value = true;
};

const deleteReview = async () => {
  if (!reviewToDelete.value) return;
  
  deleting.value = true;
  try {
    await api.reviews.delete(reviewToDelete.value.id);
    reviews.value = reviews.value.filter(r => r.id !== reviewToDelete.value.id);
    showToaster('success', 'Отзыв успешно удалён');
    deleteDialog.value = false;
  } catch (err) {
    console.error(err);
    showToaster('error', 'Ошибка при удалении отзыва');
  } finally {
    deleting.value = false;
    reviewToDelete.value = null;
  }
};

const loadReviews = async () => {
  loading.value = true;
  try {
    const response = await api.reviews.getAll();
    reviews.value = Array.isArray(response) ? response : (response as any).data || [];
  } catch (err) {
    console.error(err);
    reviews.value = [];
  } finally {
    loading.value = false;
  }
};

// Reset page when filters change
watch([searchQuery, filterRating, filterShop, filterEdited], () => {
  page.value = 1;
});

useHead({
  title: 'Отзывы',
});

onMounted(() => {
  loadReviews();
});
</script>

<style scoped>
.reviews-page {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

/* ===== HEADER & STATS ===== */
.reviews-page__header {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.reviews-page__stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}

.reviews-page__stat-card {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.25rem;
  background-color: var(--color-bg-card);
  border-radius: 1rem;
  transition: all 0.3s ease;
}

.reviews-page__stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px var(--color-shadow);
}

.reviews-page__stat-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  border-radius: 12px;
  font-size: 1.5rem;
}

.reviews-page__stat-icon--total {
  background-color: rgba(59, 130, 246, 0.15);
  color: #3b82f6;
}

.reviews-page__stat-icon--rating {
  background-color: rgba(245, 158, 11, 0.15);
  color: #f59e0b;
}

.reviews-page__stat-icon--shops {
  background-color: rgba(16, 185, 129, 0.15);
  color: #10b981;
}

.reviews-page__stat-icon--edited {
  background-color: rgba(168, 85, 247, 0.15);
  color: #a855f7;
}

.reviews-page__stat-info {
  display: flex;
  flex-direction: column;
}

.reviews-page__stat-value {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-text-primary);
}

.reviews-page__stat-label {
  font-size: 0.875rem;
  color: var(--color-text-secondary);
}

/* ===== FILTERS ===== */
.reviews-page__filters {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
}

.reviews-page__search {
  flex: 1;
  min-width: 200px;
  max-width: 400px;
}

.reviews-page__filter {
  width: 180px;
}

@media (max-width: 599px) {
  .reviews-page__filters {
    flex-direction: column;
  }
  
  .reviews-page__search,
  .reviews-page__filter {
    width: 100%;
    max-width: none;
  }
}

/* ===== LOADING & EMPTY ===== */
.reviews-page__loading,
.reviews-page__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 4rem 2rem;
  background-color: var(--color-bg-card);
  border-radius: 1rem;
  color: var(--color-text-secondary);
}

.reviews-page__empty-icon {
  font-size: 4rem;
  color: var(--color-text-muted);
}

.reviews-page__empty-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.reviews-page__empty-text {
  font-size: 0.875rem;
}

/* ===== REVIEWS GRID ===== */
.reviews-page__cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 1.25rem;
}

@media (max-width: 599px) {
  .reviews-page__cards {
    grid-template-columns: 1fr;
  }
}

/* ===== REVIEW CARD ===== */
.review-card {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  padding: 1.25rem;
  background-color: var(--color-bg-card);
  border-radius: 1rem;
  transition: all 0.3s ease;
}

.review-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 32px var(--color-shadow);
}

.review-card__header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.review-card__shop {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.review-card__shop-avatar {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background-color: var(--color-bg-tertiary);
  overflow: hidden;
}

.review-card__shop-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.review-card__shop-placeholder {
  font-size: 1.5rem;
  color: var(--color-text-muted);
}

.review-card__shop-info {
  display: flex;
  flex-direction: column;
}

.review-card__shop-name {
  font-weight: 600;
  color: var(--color-text-primary);
}

.review-card__shop-city {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}

.review-card__delete {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border: none;
  background: transparent;
  border-radius: 8px;
  color: var(--color-text-muted);
  cursor: pointer;
  transition: all 0.2s ease;
}

.review-card__delete:hover {
  background-color: rgba(239, 68, 68, 0.1);
  color: #ef4444;
}

/* ===== RATING ===== */
.review-card__rating {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.review-card__stars {
  display: flex;
  gap: 2px;
}

.review-card__star {
  font-size: 1.25rem;
  color: var(--color-text-muted);
  transition: color 0.2s ease;
}

.review-card__star--filled {
  color: #f59e0b;
}

.review-card__rating-value {
  font-weight: 700;
  color: var(--color-text-primary);
  margin-left: 0.25rem;
}

/* ===== TEXT ===== */
.review-card__text {
  flex: 1;
  font-size: 0.9375rem;
  line-height: 1.6;
  color: var(--color-text-secondary);
  display: -webkit-box;
  -webkit-line-clamp: 4;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* ===== FOOTER ===== */
.review-card__footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 0.75rem;
  border-top: 1px solid var(--color-border-light);
}

.review-card__user {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.review-card__user-avatar {
  background-color: var(--color-bg-tertiary);
  color: var(--color-text-muted);
}

.review-card__user-info {
  display: flex;
  flex-direction: column;
}

.review-card__user-name {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text-primary);
}

.review-card__date {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

/* ===== EDITED BADGE ===== */
.review-card__edited-badge {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.25rem 0.5rem;
  background-color: rgba(245, 158, 11, 0.15);
  border-radius: 6px;
  font-size: 0.75rem;
  font-weight: 500;
  color: #f59e0b;
}

.review-card__edited-badge .iconify {
  font-size: 0.875rem;
}

/* ===== PAGINATION ===== */
.reviews-page__pagination {
  display: flex;
  justify-content: center;
  padding-top: 1rem;
}

/* ===== DELETE DIALOG ===== */
.reviews-page__delete-dialog {
  background-color: var(--color-bg-card) !important;
  border-radius: 1rem !important;
}

.reviews-page__delete-title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  color: var(--color-text-primary) !important;
}

.reviews-page__delete-title .iconify {
  color: #ef4444;
  font-size: 1.5rem;
}

.reviews-page__delete-text {
  color: var(--color-text-secondary) !important;
}

.reviews-page__delete-actions {
  justify-content: flex-end;
  gap: 0.5rem;
}

/* ===== ANIMATIONS ===== */
.review-card-enter-active,
.review-card-leave-active {
  transition: all 0.3s ease;
}

.review-card-enter-from {
  opacity: 0;
  transform: translateY(20px);
}

.review-card-leave-to {
  opacity: 0;
  transform: scale(0.95);
}
</style>

