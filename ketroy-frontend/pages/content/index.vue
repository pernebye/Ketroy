<template>
  <section class="content-page">
    <div class="content-page__header">
      <tabs v-model="layoutStore.contentTab" :items="tabItems" />
      <expand>
        <div v-if="showAddButton && layoutStore.contentTab !== 'histories' && layoutStore.contentTab !== 'shops'" class="content-page__actions">
          <!-- Кнопка управления категориями (только для вкладки news) -->
          <v-btn 
            v-if="layoutStore.contentTab === 'news'" 
            variant="outlined"
            rounded="lg"
            class="content-page__categories-btn"
            @click="openCategoriesModal"
          >
            <Icon name="tabler:triangle-square-circle-filled" class="content-page__categories-icon" />
            Категории
          </v-btn>
          <!-- Для баннеров — скролл к форме добавления -->
          <btn 
            v-if="layoutStore.contentTab === 'banners'"
            text="Добавить" 
            prepend-icon="mdi-plus" 
            @click="scrollToNewBanner"
          />
          <!-- Для остальных — переход на страницу -->
          <NuxtLink v-else class="content-page__add-btn" :to="{ name: 'content-tab@id', params: { tab: layoutStore.contentTab, id: 'new' } }">
            <btn text="Добавить" prepend-icon="mdi-plus" />
          </NuxtLink>
        </div>
      </expand>
    </div>

    <transition name="content-fade" mode="out-in">
      <!-- Специальный интерфейс для историй -->
      <div v-if="layoutStore.contentTab === 'histories'" :key="'histories'" class="stories-manager">
        <div class="stories-manager__content">
          <!-- Левая панель: Список групп (актуальных) -->
          <div class="stories-manager__sidebar">
            <div class="stories-manager__sidebar-header">
              <span class="stories-manager__sidebar-title">Группы историй</span>
              <v-btn 
                icon 
                size="small" 
                variant="text" 
                :disabled="showInlineCreate"
                @click="startInlineCreate"
              >
                <Icon name="mdi:plus" />
              </v-btn>
            </div>
            
            <div class="stories-manager__groups-list">
              <div v-if="loadingGroups" class="stories-manager__loading">
                <v-progress-circular indeterminate :size="32" />
              </div>
              
              <template v-else>
                <div v-if="!groups.length && !showInlineCreate" class="stories-manager__empty">
                  <Icon name="solar:gallery-broken" />
                  <span>Групп пока нет</span>
                  <btn text="Создать" size="small" @click="startInlineCreate" />
                </div>

                <div 
                  v-for="(group, groupIndex) in groups" 
                  :key="group.id || group.name"
                  class="stories-manager__group-item"
                  :class="{ 
                    'stories-manager__group-item--active': selectedGroup?.name === group.name,
                    'stories-manager__group-item--welcome': group.is_welcome,
                    'stories-manager__group-item--dragging': draggingGroupIndex === groupIndex && isDraggingGroup
                  }"
                  draggable="true"
                  @click="selectGroup(group)"
                  @dragstart="onGroupDragStart(groupIndex, $event)"
                  @dragover="onGroupDragOver(groupIndex, $event)"
                  @drop="onGroupDrop($event)"
                  @dragend="onGroupDragEnd($event)"
                >
                  <div class="stories-manager__group-drag-handle">
                    <Icon name="mdi:drag-vertical" />
                  </div>
                  <div class="stories-manager__group-cover">
                    <img v-if="group.cover" :src="group.cover" :alt="group.name" />
                    <Icon v-else name="solar:gallery-add-linear" />
                    <div v-if="group.is_welcome" class="stories-manager__group-welcome-badge">
                      <Icon name="solar:stars-bold" />
                    </div>
                  </div>
                  <div class="stories-manager__group-info">
                    <span class="stories-manager__group-name">{{ group.name }}</span>
                    <span class="stories-manager__group-count">{{ group.stories?.length || 0 }} историй</span>
                  </div>
                </div>

                <!-- Inline создание новой группы -->
                <div v-if="showInlineCreate" class="stories-manager__inline-create">
                  <div 
                    class="stories-manager__inline-cover"
                    @click="triggerInlineCoverUpload"
                  >
                    <img v-if="inlineNewGroup.cover" :src="inlineNewGroup.cover" alt="Обложка" />
                    <Icon v-else name="solar:camera-add-bold" />
                  </div>
                  <input 
                    ref="inlineCoverInput" 
                    type="file" 
                    accept="image/*" 
                    hidden 
                    @change="onInlineCoverChange"
                  />
                  <div class="stories-manager__inline-form">
                    <input
                      ref="inlineNameInput"
                      v-model="inlineNewGroup.name"
                      type="text"
                      class="stories-manager__inline-input"
                      placeholder="Название группы..."
                      @keydown.enter="saveInlineGroup"
                      @keydown.escape="cancelInlineCreate"
                    />
                    <div class="stories-manager__inline-actions">
                      <v-btn 
                        icon 
                        size="x-small" 
                        variant="text" 
                        color="success"
                        :loading="savingInlineGroup"
                        @click="saveInlineGroup"
                      >
                        <Icon name="mdi:check" />
                      </v-btn>
                      <v-btn 
                        icon 
                        size="x-small" 
                        variant="text" 
                        @click="cancelInlineCreate"
                      >
                        <Icon name="mdi:close" />
                      </v-btn>
                    </div>
                  </div>
                </div>
              </template>
            </div>
          </div>

          <!-- Правая панель: Редактирование группы -->
          <div class="stories-manager__main">
            <template v-if="selectedGroup">
              <!-- Информация о группе -->
              <card-form class="stories-manager__group-edit">
                <div class="stories-manager__group-edit-header">
                  <h2 class="stories-manager__section-title">
                    <Icon name="solar:pen-bold" />
                    {{ isNewGroup ? 'Новая группа' : selectedGroup.name }}
                  </h2>
                  <div class="stories-manager__group-actions">
                    <v-btn 
                      v-if="!isNewGroup && !isSystemGroup"
                      icon
                      variant="text" 
                      color="error" 
                      size="default"
                      class="stories-manager__delete-group-btn"
                      @click="deleteGroup"
                    >
                      <Icon name="solar:trash-bin-trash-outline" />
                    </v-btn>
                    <btn 
                      :text="isNewGroup ? 'Создать' : 'Сохранить'" 
                      size="small"
                      :loading="savingGroup"
                      @click="saveGroup" 
                    />
                  </div>
                </div>

                <div class="stories-manager__group-form">
                  <!-- Обложка группы -->
                  <div class="stories-manager__cover-section">
                    <div 
                      class="stories-manager__cover-preview"
                      :class="{ 'stories-manager__cover-preview--empty': !selectedGroup.cover }"
                      @click="triggerCoverUpload"
                    >
                      <img v-if="selectedGroup.cover" :src="selectedGroup.cover" alt="Обложка" />
                      <div v-else class="stories-manager__cover-placeholder">
                        <Icon name="solar:camera-add-bold" />
                      </div>
                      <div class="stories-manager__cover-overlay">
                        <Icon name="solar:pen-bold" />
                      </div>
                    </div>
                    <input 
                      ref="coverInput" 
                      type="file" 
                      accept="image/*" 
                      hidden 
                      @change="onCoverChange"
                    />
                  </div>

                  <!-- Название группы -->
                  <div class="stories-manager__name-section">
                    <v-text-field
                      v-model="selectedGroup.name"
                      density="compact"
                      variant="outlined"
                      placeholder="Название группы..."
                      rounded="lg"
                      :disabled="isSystemGroup"
                      hide-details
                    />
                  </div>

                  <!-- Приветственная группа -->
                  <div class="stories-manager__welcome-section">
                    <v-switch
                      v-model="selectedGroup.is_welcome"
                      color="warning"
                      inset
                      hide-details
                      density="compact"
                      @update:model-value="onWelcomeToggle"
                    />
                    <div class="stories-manager__welcome-info">
                      <span class="stories-manager__welcome-label">Приветственная группа</span>
                      <span class="stories-manager__welcome-hint">Показывается при запуске приложения</span>
                    </div>
                  </div>
                </div>
              </card-form>

              <!-- Список историй группы -->
              <card-form v-if="!isNewGroup" class="stories-manager__stories-section">
                <div class="stories-manager__stories-header">
                  <span class="stories-manager__stories-title">Истории</span>
                  <div class="stories-manager__stories-header-actions">
                    <v-btn 
                      v-if="selectedStoryIds.length > 0" 
                      color="error"
                      variant="flat"
                      size="small"
                      rounded="lg"
                      prepend-icon="mdi-delete"
                      :loading="deletingStories"
                      class="stories-manager__delete-btn"
                      @click="deleteSelectedStories" 
                    >
                      Удалить ({{ selectedStoryIds.length }})
                    </v-btn>
                    <btn text="Добавить" prepend-icon="mdi-plus" size="small" @click="addStory" />
                  </div>
                </div>

                <div v-if="!selectedGroup.stories?.length" class="stories-manager__stories-empty">
                  <Icon name="solar:gallery-minimalistic-linear" />
                  <span>Нет историй</span>
                </div>

                <div v-else class="stories-manager__stories-grid" :class="{ 'stories-manager__stories-grid--dragging': isDraggingStory }">
                  <div 
                    v-for="(story, storyIndex) in selectedGroup.stories" 
                    :key="story.id"
                    class="stories-manager__story-card"
                    :class="{ 
                      'stories-manager__story-card--selected': selectedStoryIds.includes(story.id),
                      'stories-manager__story-card--dragging': draggingStoryIndex === storyIndex && isDraggingStory
                    }"
                    draggable="true"
                    @click="onStoryCardClick(story, $event)"
                    @dragstart="onStoryDragStart(storyIndex, $event)"
                    @dragover="onStoryDragOver(storyIndex, $event)"
                    @drop="onStoryDrop($event)"
                    @dragend="onStoryDragEnd($event)"
                  >
                    <div class="stories-manager__story-drag-handle">
                      <Icon name="mdi:drag" />
                    </div>
                    <div class="stories-manager__story-media">
                      <img v-if="story.type === 'image'" :src="story.file_path" :alt="story.name" />
                      <video v-else :src="story.file_path" />
                      <!-- Checkbox для выбора -->
                      <div 
                        class="stories-manager__story-checkbox"
                        :class="{ 'stories-manager__story-checkbox--checked': selectedStoryIds.includes(story.id) }"
                        @click.stop="toggleStorySelection(story.id)"
                      >
                        <Icon v-if="selectedStoryIds.includes(story.id)" name="mdi:check" />
                      </div>
                    </div>
                    <div class="stories-manager__story-footer">
                      <span class="stories-manager__story-name">{{ story.name || 'История' }}</span>
                      <div class="stories-manager__story-actions">
                        <!-- Toggle активации -->
                        <div class="stories-manager__story-toggle" @click.stop>
                          <label class="ios-toggle ios-toggle--small">
                            <input 
                              type="checkbox" 
                              :checked="story.is_active" 
                              @change="toggleStoryActive(story)"
                            />
                            <span class="ios-toggle__slider"></span>
                          </label>
                        </div>
                        <!-- Кнопка удаления -->
                        <v-btn icon size="small" variant="text" color="error" class="stories-manager__story-btn" @click.stop="deleteStory(story)">
                          <Icon name="solar:trash-bin-trash-outline" />
                        </v-btn>
                      </div>
                    </div>
                  </div>
                </div>
              </card-form>
            </template>

            <!-- Пустое состояние -->
            <div v-else class="stories-manager__no-selection">
              <Icon name="solar:hand-shake-linear" />
              <p>Выберите группу слева</p>
            </div>
          </div>
        </div>

        <!-- Модальное окно добавления/редактирования истории -->
        <v-dialog v-model="storyDialog" max-width="680" persistent>
          <v-card rounded="xl" class="story-dialog">
            <v-card-title class="story-dialog__title">
              <Icon name="solar:video-frame-play-vertical-bold" />
              {{ editingStory?.id ? 'Редактирование' : 'Новая история' }}
            </v-card-title>
            
            <v-card-text class="story-dialog__content">
              <div class="story-dialog__layout">
                <!-- Левая часть: загрузка медиа -->
                <div class="story-dialog__left">
                  <div class="story-dialog__type-switch">
                    <v-btn-toggle v-model="editingStory.type" mandatory color="primary" rounded="lg" density="compact">
                      <v-btn value="image" variant="outlined" size="small">
                        <Icon name="solar:gallery-bold" />
                        Фото
                      </v-btn>
                      <v-btn value="video" variant="outlined" size="small">
                        <Icon name="solar:videocamera-bold" />
                        Видео
                      </v-btn>
                    </v-btn-toggle>
                  </div>
                  <div 
                    class="story-dialog__media-upload"
                    :class="{ 'story-dialog__media-upload--has-media': editingStory.file_path }"
                    @click="triggerMediaUpload"
                  >
                    <template v-if="editingStory.file_path">
                      <img v-if="editingStory.type === 'image'" :src="editingStory.file_path" alt="Preview" />
                      <video v-else :src="editingStory.file_path" />
                      <div class="story-dialog__media-overlay">
                        <Icon name="solar:pen-bold" />
                      </div>
                    </template>
                    <template v-else>
                      <Icon :name="editingStory.type === 'video' ? 'solar:videocamera-add-bold' : 'solar:gallery-add-bold'" />
                      <span>Загрузить</span>
                      <span class="story-dialog__format-hint">9:16</span>
                    </template>
                  </div>
                  <input 
                    ref="mediaInput" 
                    type="file" 
                    :accept="editingStory.type === 'video' ? 'video/*' : 'image/*'" 
                    hidden 
                    @change="onMediaChange"
                  />
                </div>

                <!-- Правая часть: настройки -->
                <div class="story-dialog__right">
                  <div class="story-dialog__field">
                    <label class="story-dialog__label">Название</label>
                    <v-text-field
                      v-model="editingStory.name"
                      density="compact"
                      variant="outlined"
                      placeholder="Опционально..."
                      rounded="lg"
                      hide-details
                    />
                  </div>

                  <div class="story-dialog__field">
                    <label class="story-dialog__label">Города</label>
                    <div class="story-dialog__cities-badges">
                      <button
                        v-for="city in storyCities"
                        :key="city"
                        type="button"
                        class="story-dialog__city-badge"
                        :class="{ 'story-dialog__city-badge--active': editingStory.cities?.includes(city) }"
                        @click="toggleStoryCity(city)"
                      >
                        {{ city }}
                      </button>
                    </div>
                  </div>

                  <div class="story-dialog__field story-dialog__field--switch">
                    <label class="story-dialog__label">Статус</label>
                    <div class="story-dialog__switch">
                      <v-switch 
                        v-model="editingStory.is_active" 
                        color="success" 
                        inset
                        hide-details
                        density="compact"
                      />
                      <span class="story-dialog__switch-label">{{ editingStory.is_active ? 'Активна' : 'Скрыта' }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </v-card-text>

            <v-card-actions class="story-dialog__actions">
              <v-btn variant="text" @click="closeStoryDialog">Отмена</v-btn>
              <btn 
                :text="editingStory?.id ? 'Сохранить' : 'Добавить'" 
                :loading="savingStory"
                :disabled="!editingStory.file_path"
                @click="saveStory" 
              />
            </v-card-actions>
          </v-card>
        </v-dialog>

        <!-- Диалог кропа для обложки группы историй (1:1 квадрат) -->
        <v-dialog v-model="coverCropDialog" max-width="800px" persistent>
          <v-card class="crop-dialog">
            <v-card-title class="crop-dialog__title">
              <Icon name="mdi:crop" />
              Обрезка обложки группы
              <span class="crop-dialog__ratio">1:1</span>
            </v-card-title>
            <v-card-text>
              <div v-if="coverCropImageUrl" class="crop-dialog__container">
                <img 
                  ref="coverCropImageEl" 
                  class="crop-dialog__image" 
                  :src="coverCropImageUrl" 
                  alt="Редактируемое изображение" 
                />
              </div>
              <div v-else class="crop-dialog__loading">
                <v-progress-circular indeterminate />
                <p>Загрузка изображения...</p>
              </div>
            </v-card-text>
            <v-card-actions class="crop-dialog__actions">
              <v-btn variant="text" @click="closeCoverCropDialog">Отмена</v-btn>
              <v-btn color="primary" variant="flat" @click="applyCoverCrop">
                <Icon name="mdi:check" />
                Применить
              </v-btn>
            </v-card-actions>
          </v-card>
        </v-dialog>

        <!-- Диалог кропа для медиа истории (9:16 вертикальный) -->
        <v-dialog v-model="mediaCropDialog" max-width="800px" persistent>
          <v-card class="crop-dialog">
            <v-card-title class="crop-dialog__title">
              <Icon name="mdi:crop" />
              Обрезка изображения истории
              <span class="crop-dialog__ratio">9:16</span>
            </v-card-title>
            <v-card-text>
              <div v-if="mediaCropImageUrl" class="crop-dialog__container">
                <img 
                  ref="mediaCropImageEl" 
                  class="crop-dialog__image" 
                  :src="mediaCropImageUrl" 
                  alt="Редактируемое изображение" 
                />
              </div>
              <div v-else class="crop-dialog__loading">
                <v-progress-circular indeterminate />
                <p>Загрузка изображения...</p>
              </div>
            </v-card-text>
            <v-card-actions class="crop-dialog__actions">
              <v-btn variant="text" @click="closeMediaCropDialog">Отмена</v-btn>
              <v-btn color="primary" variant="flat" @click="applyMediaCrop">
                <Icon name="mdi:check" />
                Применить
              </v-btn>
            </v-card-actions>
          </v-card>
        </v-dialog>
      </div>

      <!-- Специальный интерфейс для баннеров -->
      <div v-else-if="layoutStore.contentTab === 'banners'" :key="'banners'" class="banners-manager">
        <div class="banners-manager__content">
          <!-- Левая панель: Предпросмотр как в приложении -->
          <div class="banners-manager__preview">
            <div class="banners-manager__preview-header">
              <span class="banners-manager__preview-title">Предпросмотр витрины</span>
              <v-select
                v-model="previewCity"
                :items="['Все', ...bannerCities]"
                density="compact"
                variant="outlined"
                rounded="lg"
                hide-details
                style="max-width: 120px"
              />
            </div>
            
            <div class="banners-manager__phone">
              <div class="banners-manager__phone-frame">
                <!-- Dynamic Island -->
                <div class="banners-manager__phone-island"></div>
                
                <!-- Экран приложения -->
                <div class="banners-manager__phone-screen">
                  <!-- Баннер-карусель -->
                  <div class="banners-manager__app-banner">
                    <div 
                      v-if="activeBanners.length"
                      class="banners-manager__app-banner-track"
                      :style="{ transform: `translateX(-${carouselIndex * 100}%)` }"
                    >
                      <div 
                        v-for="banner in activeBanners" 
                        :key="banner.id"
                        class="banners-manager__app-banner-slide"
                      >
                        <img :src="banner.file_path" :alt="banner.name" />
                      </div>
                    </div>
                    <div v-else class="banners-manager__app-banner-empty">
                      <Icon name="solar:gallery-broken" />
                    </div>
                    <!-- Индикаторы -->
                    <div v-if="activeBanners.length > 1" class="banners-manager__app-banner-dots">
                      <span 
                        v-for="(_, i) in activeBanners" 
                        :key="i"
                        :class="{ active: i === carouselIndex }"
                        @click="carouselIndex = i"
                      ></span>
                    </div>
                  </div>

                  <!-- Сторисы mockup -->
                  <div class="banners-manager__app-stories">
                    <div class="banners-manager__app-story">
                      <div class="banners-manager__app-story-ring">
                        <div class="banners-manager__app-story-avatar"></div>
                      </div>
                      <span>Ketroy</span>
                    </div>
                    <div class="banners-manager__app-story">
                      <div class="banners-manager__app-story-ring">
                        <div class="banners-manager__app-story-avatar"></div>
                      </div>
                      <span>Наши гости</span>
                    </div>
                    <div class="banners-manager__app-story">
                      <div class="banners-manager__app-story-ring">
                        <div class="banners-manager__app-story-avatar"></div>
                      </div>
                      <span>Образы</span>
                    </div>
                  </div>

                  <!-- Новости mockup -->
                  <div class="banners-manager__app-news">
                    <div class="banners-manager__app-news-header">
                      <span class="banners-manager__app-news-title">Новости</span>
                    </div>
                    <div class="banners-manager__app-news-filters">
                      <span class="active">All</span>
                      <span>Новинки</span>
                      <span>Образы</span>
                    </div>
                    <div class="banners-manager__app-news-card"></div>
                  </div>
                </div>

                <!-- Навбар -->
                <div class="banners-manager__phone-navbar">
                  <div class="banners-manager__phone-navbar-item active">
                    <Icon name="solar:shop-2-outline" />
                    <span>Витрина</span>
                  </div>
                  <div class="banners-manager__phone-navbar-item">
                    <Icon name="solar:restart-outline" />
                    <span>AI</span>
                  </div>
                  <div class="banners-manager__phone-navbar-item">
                    <Icon name="solar:qr-code-outline" />
                  </div>
                  <div class="banners-manager__phone-navbar-item">
                    <Icon name="solar:gift-outline" />
                    <span>Подарки</span>
                  </div>
                  <div class="banners-manager__phone-navbar-item">
                    <Icon name="solar:user-circle-outline" />
                    <span>Профиль</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Правая панель: Список всех баннеров -->
          <div class="banners-manager__list">
            <div class="banners-manager__list-header">
              <span class="banners-manager__list-title">Все баннеры ({{ banners.length }})</span>
            </div>

            <div v-if="loadingBanners" class="banners-manager__loading">
              <v-progress-circular indeterminate :size="32" />
            </div>

            <div v-else class="banners-manager__items" :class="{ 'banners-manager__items--dragging': isDraggingBanner }">
              <!-- Существующие баннеры -->
              <div 
                v-for="(banner, bannerIndex) in banners" 
                :key="banner.id"
                class="banners-manager__item"
                :class="{ 
                  'banners-manager__item--inactive': !banner.is_active,
                  'banners-manager__item--scheduled': isBannerScheduled(banner),
                  'banners-manager__item--expired': isBannerExpired(banner),
                  'banners-manager__item--dragging': draggingBannerIndex === bannerIndex && isDraggingBanner
                }"
                draggable="true"
                @dragstart="onBannerDragStart(bannerIndex, $event)"
                @dragover="onBannerDragOver(bannerIndex, $event)"
                @drop="onBannerDrop($event)"
                @dragend="onBannerDragEnd($event)"
              >
                <!-- Превью изображения -->
                <div class="banners-manager__item-preview" @click="openBannerImageDialog(banner)">
                  <img v-if="banner.file_path" :src="banner.file_path" :alt="banner.name" />
                  <div v-else class="banners-manager__item-preview-empty">
                    <Icon name="solar:gallery-add-outline" />
                  </div>
                  <div class="banners-manager__item-preview-overlay">
                    <Icon name="solar:pen-new-square-outline" />
                  </div>
                </div>

                <!-- Название и города -->
                <div class="banners-manager__item-form">
                  <!-- Название: режим просмотра / редактирования -->
                  <div class="banners-manager__item-name-row">
                    <span 
                      v-if="editingBannerId !== banner.id"
                      class="banners-manager__item-name"
                      @dblclick="startEditingBannerName(banner)"
                    >
                      {{ banner.name || 'Без названия' }}
                    </span>
                    <input
                      v-else
                      :ref="el => setBannerNameInputRef(el, banner.id)"
                      v-model="banner.name"
                      type="text"
                      class="banners-manager__item-input"
                      placeholder="Название баннера..."
                      @blur="finishEditingBannerName(banner)"
                      @keydown.enter="($event.target as HTMLInputElement).blur()"
                      @keydown.escape="cancelEditingBannerName(banner)"
                    />
                    <v-btn 
                      v-if="editingBannerId !== banner.id"
                      icon 
                      size="x-small" 
                      variant="text" 
                      class="banners-manager__item-edit-btn"
                      @click="startEditingBannerName(banner)"
                    >
                      <Icon name="solar:pen-outline" />
                    </v-btn>
                  </div>
                  
                  <!-- Города как бейджики -->
                  <div class="banners-manager__item-cities-badges">
                    <button
                      v-for="city in allCities"
                      :key="city"
                      class="banners-manager__city-badge"
                      :class="{ 'banners-manager__city-badge--active': banner.cities?.includes(city) }"
                      @click="toggleBannerCity(banner, city)"
                    >
                      {{ city }}
                    </button>
                  </div>
                </div>

                <!-- Период -->
                <div class="banners-manager__item-period-section">
                  <v-menu :close-on-content-click="false">
                    <template #activator="{ props }">
                      <div v-bind="props" class="banners-manager__item-period-btn">
                        <Icon name="solar:calendar-outline" />
                        <span v-if="banner.start_date || banner.expired_at">
                          {{ banner.start_date ? formatDate(banner.start_date) : '...' }}
                          —
                          {{ banner.expired_at ? formatDate(banner.expired_at) : '∞' }}
                        </span>
                        <span v-else>Всегда</span>
                      </div>
                    </template>
                    <v-card rounded="lg" class="banners-manager__period-menu">
                      <div class="banners-manager__period-presets">
                        <span class="banners-manager__period-label">Быстрый период</span>
                        <div class="banners-manager__period-buttons">
                          <v-btn size="small" variant="tonal" @click="setBannerPeriod(banner, 7)">7 дней</v-btn>
                          <v-btn size="small" variant="tonal" @click="setBannerPeriod(banner, 14)">14 дней</v-btn>
                          <v-btn size="small" variant="tonal" @click="setBannerPeriod(banner, 30)">30 дней</v-btn>
                        </div>
                      </div>
                      <v-divider class="my-2" />
                      <div class="banners-manager__period-custom">
                        <span class="banners-manager__period-label">Свой период</span>
                        <div class="banners-manager__period-dates">
                          <v-text-field
                            :model-value="banner.start_date?.split('T')[0]"
                            type="date"
                            density="compact"
                            variant="outlined"
                            rounded="lg"
                            hide-details
                            label="С"
                            @update:model-value="updateBannerDate(banner, 'start_date', $event)"
                          />
                          <v-text-field
                            :model-value="banner.expired_at?.split('T')[0]"
                            type="date"
                            density="compact"
                            variant="outlined"
                            rounded="lg"
                            hide-details
                            label="По"
                            @update:model-value="updateBannerDate(banner, 'expired_at', $event)"
                          />
                        </div>
                        <v-btn size="small" variant="text" color="error" @click="clearBannerPeriod(banner)">
                          Сбросить
                        </v-btn>
                      </div>
                    </v-card>
                  </v-menu>
                </div>

                <!-- Контролы -->
                <div class="banners-manager__item-controls">
                  <v-switch
                    :model-value="banner.is_active"
                    color="success"
                    inset
                    hide-details
                    density="compact"
                    class="banners-manager__switch"
                    @update:model-value="toggleBannerActive(banner)"
                  />
                  <v-btn icon size="small" variant="text" color="error" class="banners-manager__item-btn" @click="deleteBanner(banner)">
                    <Icon name="solar:trash-bin-trash-outline" />
                  </v-btn>
                </div>
              </div>

              <!-- Inline создание нового баннера -->
              <div v-if="showNewBannerForm" ref="newBannerFormRef" class="banners-manager__item banners-manager__item--new">
                <div class="banners-manager__item-preview" @click="openBannerImageDialog(newBanner)">
                  <img v-if="newBanner.file_path" :src="newBanner.file_path" alt="Новый баннер" />
                  <div v-else class="banners-manager__item-preview-empty">
                    <Icon name="solar:gallery-add-outline" />
                    <span>Загрузить</span>
                  </div>
                </div>

                <div class="banners-manager__item-form">
                  <input
                    ref="newBannerNameInput"
                    v-model="newBanner.name"
                    type="text"
                    class="banners-manager__item-input"
                    placeholder="Название баннера..."
                  />
                  
                  <!-- Города как бейджики для нового баннера -->
                  <div class="banners-manager__item-cities-badges">
                    <button
                      v-for="city in allCities"
                      :key="city"
                      class="banners-manager__city-badge"
                      :class="{ 'banners-manager__city-badge--active': newBanner.cities?.includes(city) }"
                      @click="toggleNewBannerCity(city)"
                    >
                      {{ city }}
                    </button>
                  </div>
                </div>

                <div class="banners-manager__item-controls">
                  <v-btn 
                    color="success" 
                    size="small" 
                    variant="tonal"
                    :loading="savingNewBanner"
                    :disabled="!newBanner.file_path || !newBanner.name"
                    @click="saveNewBanner"
                  >
                    <Icon name="solar:check-circle-outline" />
                    Сохранить
                  </v-btn>
                  <v-btn size="small" variant="text" @click="cancelNewBanner">
                    Отмена
                  </v-btn>
                </div>
              </div>

              <!-- Кнопка добавления -->
              <div v-if="!showNewBannerForm" class="banners-manager__add-btn" @click="startNewBanner">
                <Icon name="solar:add-circle-outline" />
                <span>Добавить баннер</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Модальное окно загрузки изображения/видео -->
        <v-dialog v-model="bannerImageDialog" max-width="600" persistent>
          <v-card rounded="xl" class="banner-image-dialog">
            <v-card-title class="banner-image-dialog__title">
              <Icon name="solar:gallery-bold" />
              Медиа для баннера
            </v-card-title>
            <v-card-text class="banner-image-dialog__content">
              <video-file-input 
                v-model="bannerImageFile"
                class="banner-image-dialog__input"
                :aspect-ratio="3/4"
                :max-duration="15"
                @handlePhotoUpload="onBannerImageUpload"
                @error="onBannerUploadError"
              >
                <template #default>
                  <div class="banner-image-dialog__dropzone">
                    <Icon name="solar:gallery-add-outline" />
                    <span>Перетащите изображение или видео</span>
                    <span class="banner-image-dialog__hint">JPG, PNG, GIF или видео (MP4, MOV, HEVC)</span>
                    <span class="banner-image-dialog__hint-video">
                      <Icon name="solar:videocamera-outline" />
                      Видео автоконвертируется в GIF (до 15 сек)
                    </span>
                  </div>
                </template>
              </video-file-input>
            </v-card-text>
            <v-card-actions class="banner-image-dialog__actions">
              <v-btn variant="text" @click="closeBannerImageDialog">Отмена</v-btn>
              <v-btn 
                color="primary" 
                variant="flat" 
                :disabled="!bannerImageFile"
                @click="applyBannerImage"
              >
                Применить
              </v-btn>
            </v-card-actions>
          </v-card>
        </v-dialog>
      </div>

      <!-- Специальный интерфейс для новостей -->
      <div v-else-if="layoutStore.contentTab === 'news'" :key="'news'" class="news-manager">
        <!-- Поисковик и кнопка массового удаления -->
        <div class="news-manager__header">
          <div class="news-manager__search">
            <v-text-field
              v-model="newsSearch"
              density="compact"
              variant="outlined"
              rounded="lg"
              placeholder="Поиск по названию..."
              prepend-inner-icon="mdi-magnify"
              hide-details
              clearable
              class="news-manager__search-input"
            />
            <span class="news-manager__search-count">
              {{ filteredNews.length }} из {{ showNewsArchive ? archivedNewsList.length : newsList.length }}
            </span>
          </div>
          <div class="news-manager__header-actions">
            <!-- Кнопка массовой архивации (в обычном режиме) -->
            <v-btn 
              v-if="selectedNewsIds.length > 0 && !showNewsArchive" 
              color="warning"
              variant="flat"
              size="small"
              rounded="lg"
              prepend-icon="mdi-archive-arrow-down"
              :loading="archivingNews"
              @click="archiveSelectedNews" 
            >
              В архив ({{ selectedNewsIds.length }})
            </v-btn>
            <!-- Кнопка массового удаления (в режиме архива) -->
            <v-btn 
              v-if="selectedNewsIds.length > 0 && showNewsArchive" 
              color="error"
              variant="flat"
              size="small"
              rounded="lg"
              prepend-icon="mdi-delete"
              :loading="deletingNews"
              @click="deleteSelectedNews" 
            >
              Удалить ({{ selectedNewsIds.length }})
            </v-btn>
            <!-- Переключатель архива -->
            <v-btn
              :color="showNewsArchive ? 'warning' : 'default'"
              :variant="showNewsArchive ? 'flat' : 'outlined'"
              size="small"
              rounded="lg"
              :prepend-icon="showNewsArchive ? 'mdi-archive' : 'mdi-archive-outline'"
              @click="toggleNewsArchive"
            >
              {{ showNewsArchive ? 'Выйти из архива' : 'Архив' }}
            </v-btn>
          </div>
        </div>

        <div v-if="loadingNews" class="news-manager__loading">
          <v-progress-circular indeterminate :size="48" />
        </div>

        <div v-else-if="!filteredNews.length" class="news-manager__empty">
          <Icon :name="showNewsArchive ? 'solar:archive-broken' : 'solar:document-text-broken'" />
          <span>{{ newsSearch ? 'Ничего не найдено' : (showNewsArchive ? 'Архив пуст' : 'Новостей пока нет') }}</span>
        </div>

        <TransitionGroup 
          v-else
          tag="div" 
          :name="isModeSwitching ? 'news-fade' : 'news-grid'" 
          class="news-manager__grid" 
          :class="{ 'news-manager__grid--dragging': isDraggingNews }"
        >
          <div 
            v-for="(news, newsIndex) in filteredNews" 
            :key="news.id"
            class="news-manager__card"
            :class="{ 
              'news-manager__card--inactive': !news.is_active && !showNewsArchive,
              'news-manager__card--archived': showNewsArchive,
              'news-manager__card--selected': selectedNewsIds.includes(news.id),
              'news-manager__card--dragging': draggingNewsIndex === newsIndex && isDraggingNews && !showNewsArchive
            }"
            :draggable="!showNewsArchive"
            @dragstart="!showNewsArchive && onNewsDragStart(newsIndex, $event)"
            @dragover="!showNewsArchive && onNewsDragOver(newsIndex, $event)"
            @drop="!showNewsArchive && onNewsDrop($event)"
            @dragend="!showNewsArchive && onNewsDragEnd($event)"
            @click="navigateToNewsEdit(news, $event)"
          >
            <div class="news-manager__card-image">
              <img v-if="news.image" :src="news.image" :alt="news.name" />
              <div v-else class="news-manager__card-image-empty">
                <Icon name="solar:gallery-broken" />
              </div>
              <!-- Чекбокс для выбора (появляется при наведении) -->
              <div 
                class="news-manager__card-checkbox"
                :class="{ 'news-manager__card-checkbox--checked': selectedNewsIds.includes(news.id) }"
                @click.stop="toggleNewsSelection(news.id)"
              >
                <Icon v-if="selectedNewsIds.includes(news.id)" name="mdi:check" />
              </div>
              <!-- Бейджик категории -->
              <div v-if="news.category && formatNewsCategory(news.category)" class="news-manager__card-category-badge">
                {{ formatNewsCategory(news.category) }}
              </div>
              <div v-if="showNewsArchive" class="news-manager__card-archived-badge">
                <Icon name="mdi:archive" />
                Архив
              </div>
              <div v-else-if="!news.is_active" class="news-manager__card-inactive-badge">
                Скрыта
              </div>
            </div>
            
            <div class="news-manager__card-content">
              <h3 class="news-manager__card-title">{{ news.name }}</h3>
              <p v-if="news.excerpt" class="news-manager__card-excerpt">{{ news.excerpt }}</p>
              
              <div class="news-manager__card-meta">
                <span class="news-manager__card-date">
                  <Icon name="solar:calendar-outline" />
                  {{ formatNewsDate(news.created_at) }}
                </span>
              </div>
            </div>
            
            <div class="news-manager__card-actions">
              <!-- В обычном режиме -->
              <template v-if="!showNewsArchive">
                <v-switch
                  :model-value="news.is_active"
                  color="success"
                  inset
                  hide-details
                  density="compact"
                  class="news-manager__switch"
                  @update:model-value="toggleNewsActive(news)"
                />
                <NuxtLink :to="{ name: 'content-tab@id', params: { tab: 'news', id: news.id } }">
                  <v-btn icon size="small" variant="text" class="news-manager__card-btn">
                    <Icon name="solar:pen-new-square-outline" />
                  </v-btn>
                </NuxtLink>
                <v-btn icon size="small" variant="text" color="warning" class="news-manager__card-btn" @click.stop="archiveNews(news)">
                  <Icon name="mdi:archive-arrow-down-outline" />
                </v-btn>
              </template>
              <!-- В режиме архива -->
              <template v-else>
                <v-btn 
                  size="small" 
                  variant="tonal" 
                  color="success" 
                  rounded="lg"
                  prepend-icon="mdi:restore"
                  class="news-manager__restore-btn"
                  @click.stop="restoreNews(news)"
                >
                  Восстановить
                </v-btn>
                <v-btn icon size="small" variant="text" color="error" class="news-manager__card-btn" @click.stop="deleteNewsFromArchive(news)">
                  <Icon name="solar:trash-bin-trash-outline" />
                </v-btn>
              </template>
            </div>
          </div>
        </TransitionGroup>
      </div>

      <!-- Специальный интерфейс для магазинов -->
      <div v-else-if="layoutStore.contentTab === 'shops'" :key="'shops'" class="shops-manager">
        <div class="shops-manager__header">
          <div class="shops-manager__search">
            <v-text-field
              v-model="shopsSearch"
              density="compact"
              variant="outlined"
              rounded="lg"
              placeholder="Поиск по названию или городу..."
              prepend-inner-icon="mdi-magnify"
              hide-details
              clearable
              class="shops-manager__search-input"
            />
            <span class="shops-manager__search-count">
              {{ filteredShops.length }} магазинов
            </span>
          </div>
          <div class="shops-manager__actions">
            <v-btn
              variant="outlined"
              rounded="lg"
              class="shops-manager__cities-btn"
              @click="openCitiesModal"
            >
              <Icon name="ph:city" class="shops-manager__cities-icon" />
              Города
            </v-btn>
            <v-btn
              color="primary"
              variant="flat"
              rounded="lg"
              prepend-icon="mdi-plus"
              @click="openShopModal()"
            >
              Добавить
            </v-btn>
          </div>
        </div>
        
        <div v-if="loadingShops" class="shops-manager__loading">
          <v-progress-circular indeterminate :size="48" :width="4" />
          <span>Загрузка магазинов...</span>
        </div>
        
        <div v-else-if="!filteredShops.length" class="shops-manager__empty">
          <Icon name="solar:shop-2-outline" />
          <span>Магазинов пока нет</span>
          <v-btn color="primary" variant="flat" rounded="lg" @click="openShopModal()">
            Создать первый магазин
          </v-btn>
        </div>
        
        <TransitionGroup v-else name="shop-card" tag="div" class="shops-manager__grid">
          <div 
            v-for="shop in filteredShops" 
            :key="shop.id"
            class="shop-card"
            :class="{ 'shop-card--inactive': !shop.is_active }"
          >
            <div class="shop-card__image">
              <img v-if="shop.file_path" :src="shop.file_path" :alt="shop.name" />
              <div v-else class="shop-card__image-placeholder">
                <Icon name="solar:shop-2-outline" />
              </div>
              <div v-if="!shop.is_active" class="shop-card__status-badge">
                <Icon name="mdi:eye-off" />
                Скрыт
              </div>
            </div>
            
            <div class="shop-card__content">
              <div class="shop-card__header">
                <h3 class="shop-card__title">{{ shop.name }}</h3>
                <v-chip size="small" :color="shop.is_active ? 'success' : 'default'" variant="flat">
                  {{ shop.is_active ? 'Активен' : 'Скрыт' }}
                </v-chip>
              </div>
              
              <div class="shop-card__info">
                <div class="shop-card__info-row">
                  <Icon name="solar:map-point-outline" />
                  <span>{{ shop.city }}</span>
                </div>
                <div v-if="shop.address" class="shop-card__info-row shop-card__info-row--secondary">
                  <span>{{ shop.address }}</span>
                </div>
                <div v-if="shop.opening_hours" class="shop-card__info-row">
                  <Icon name="solar:clock-circle-outline" />
                  <span>{{ shop.opening_hours }}</span>
                </div>
              </div>
              
              <!-- Социальные кнопки -->
              <div class="shop-card__socials">
                <a 
                  v-if="shop.instagram" 
                  :href="formatInstagramUrl(shop.instagram)" 
                  target="_blank"
                  class="shop-card__social shop-card__social--instagram"
                  title="Открыть Instagram"
                  @click.stop
                >
                  <Icon name="mdi:instagram" />
                </a>
                <button 
                  v-else
                  class="shop-card__social shop-card__social--disabled"
                  title="Instagram не указан"
                  disabled
                >
                  <Icon name="mdi:instagram" />
                </button>
                
                <a 
                  v-if="shop.whatsapp" 
                  :href="formatWhatsAppUrl(shop.whatsapp)" 
                  target="_blank"
                  class="shop-card__social shop-card__social--whatsapp"
                  title="Открыть WhatsApp"
                  @click.stop
                >
                  <Icon name="mdi:whatsapp" />
                </a>
                <button 
                  v-else
                  class="shop-card__social shop-card__social--disabled"
                  title="WhatsApp не указан"
                  disabled
                >
                  <Icon name="mdi:whatsapp" />
                </button>
                
                <a 
                  v-if="shop.two_gis_address" 
                  :href="shop.two_gis_address" 
                  target="_blank"
                  class="shop-card__social shop-card__social--2gis"
                  title="Открыть 2GIS"
                  @click.stop
                >
                  <Icon name="mdi:map-marker" />
                  <span>2GIS</span>
                </a>
                <button 
                  v-else
                  class="shop-card__social shop-card__social--disabled"
                  title="2GIS не указан"
                  disabled
                >
                  <Icon name="mdi:map-marker" />
                  <span>2GIS</span>
                </button>
              </div>
              
              <div class="shop-card__actions">
                <v-btn
                  variant="text"
                  size="small"
                  color="primary"
                  @click="openShopModal(shop)"
                >
                  <Icon name="solar:pen-2-outline" size="18" />
                  Редактировать
                </v-btn>
                <v-btn
                  icon
                  variant="text"
                  size="small"
                  color="error"
                  @click="deleteShop(shop)"
                >
                  <Icon name="solar:trash-bin-trash-outline" size="20" />
                </v-btn>
              </div>
            </div>
          </div>
        </TransitionGroup>
      </div>

      <!-- Стандартный список для остальных вкладок -->
      <div v-else :key="layoutStore.contentTab" class="content-page__content" :class="{ 'content-page__content--loading': loading }">
        <a-list :title="t(`admin.content.${layoutStore.contentTab}`)" :list="list" :loading="loading" @delete="onDelete" />
      </div>
    </transition>

    <!-- Modal: Управление категориями -->
    <v-dialog v-model="showCategoriesModal" max-width="600" persistent>
      <v-card rounded="xl" class="categories-modal">
        <v-card-title class="categories-modal__title">
          <Icon name="tabler:triangle-square-circle-filled" />
          Управление категориями
        </v-card-title>
        <v-card-text class="categories-modal__content">
          <div class="categories-modal__add-form">
            <v-text-field
              v-model="newCategoryName"
              density="compact"
              variant="outlined"
              placeholder="Введите название категории..."
              rounded="lg"
              hide-details
              class="categories-modal__input"
              @keyup.enter="addCategory"
            />
            <v-btn
              color="primary"
              variant="flat"
              rounded="lg"
              :loading="categoryLoading"
              :disabled="!newCategoryName.trim() || categoryLoading"
              @click="addCategory"
            >
              <Icon name="mdi:plus" />
              Добавить
            </v-btn>
          </div>
          <div class="categories-modal__list-container">
            <div v-if="categoriesLoading" class="categories-modal__loading">
              <v-progress-circular indeterminate :size="32" :width="3" />
              <span>Загрузка...</span>
            </div>
            <div v-else-if="!categories.length" class="categories-modal__empty">
              <Icon name="pepicons-pencil:list-off" />
              <span>Категорий пока нет</span>
            </div>
            <div v-else class="categories-modal__list" :class="{ 'categories-modal__list--dragging': isDraggingCategory }">
              <div 
                v-for="(category, index) in categories" 
                :key="category.id || index" 
                class="categories-modal__item"
                :class="{ 
                  'categories-modal__item--dragging': draggingCategoryIndex === index && isDraggingCategory,
                  'categories-modal__item--editing': editingCategoryIndex === index
                }"
                :draggable="editingCategoryIndex !== index"
                @dragstart="editingCategoryIndex !== index && onCategoryDragStart(index, $event)"
                @dragover="onCategoryDragOver(index, $event)"
                @drop="onCategoryDrop($event)"
                @dragend="onCategoryDragEnd($event)"
              >
                <div class="categories-modal__item-drag">
                  <Icon name="mdi:drag-vertical" />
                </div>
                
                <!-- Режим просмотра -->
                <span v-if="editingCategoryIndex !== index" class="categories-modal__item-name">
                  {{ category.name }}
                </span>
                
                <!-- Режим редактирования -->
                <input
                  v-else
                  :ref="el => setCategoryEditInputRef(el, index)"
                  v-model="editingCategoryName"
                  type="text"
                  class="categories-modal__item-edit-input"
                  placeholder="Название категории..."
                  @blur="saveEditCategory(index)"
                  @keydown.enter="($event.target as HTMLInputElement).blur()"
                  @keydown.escape="cancelEditCategory"
                />
                
                <!-- Действия (показываются при hover) -->
                <div class="categories-modal__item-actions">
                  <v-btn 
                    v-if="editingCategoryIndex !== index"
                    icon 
                    size="small" 
                    variant="text" 
                    @click.stop="startEditCategory(index)"
                  >
                    <Icon name="solar:pen-outline" size="18" />
                  </v-btn>
                  <v-btn 
                    icon 
                    size="small" 
                    variant="text" 
                    color="error" 
                    :loading="deletingCategoryId === category.id" 
                    @click.stop="deleteCategory(category)"
                  >
                    <Icon name="mdi:delete-outline" size="18" />
                  </v-btn>
                </div>
              </div>
            </div>
          </div>
        </v-card-text>
        <v-card-actions class="categories-modal__actions">
          <v-btn variant="text" @click="closeCategoriesModal">Закрыть</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Modal: Создание/Редактирование магазина -->
    <v-dialog v-model="showShopModal" max-width="700" persistent>
      <v-card rounded="xl" class="shop-modal">
        <v-card-title class="shop-modal__title">
          <Icon name="solar:shop-2-outline" />
          {{ editingShop ? 'Редактирование магазина' : 'Новый магазин' }}
        </v-card-title>
        
        <v-card-text class="shop-modal__content">
          <v-form ref="shopForm" @submit.prevent="saveShop">
            <div class="shop-modal__grid">
              <!-- Фото магазина -->
              <div class="shop-modal__image-section">
                <div 
                  class="shop-modal__image-upload"
                  @click="triggerShopImageUpload"
                >
                  <img v-if="shopFormData.image" :src="shopFormData.image" alt="Фото магазина" />
                  <div v-else class="shop-modal__image-placeholder">
                    <Icon name="solar:camera-add-bold" />
                    <span>Добавить фото</span>
                  </div>
                </div>
                <input 
                  ref="shopImageInput" 
                  type="file" 
                  accept="image/*" 
                  hidden 
                  @change="onShopImageChange"
                />
                <v-btn 
                  v-if="shopFormData.image" 
                  variant="text" 
                  size="small" 
                  color="error"
                  @click="shopFormData.image = ''"
                >
                  Удалить фото
                </v-btn>
              </div>
              
              <!-- Основные поля -->
              <div class="shop-modal__fields">
                <v-text-field
                  v-model="shopFormData.name"
                  label="Название магазина"
                  density="compact"
                  variant="outlined"
                  rounded="lg"
                  :rules="[v => !!v || 'Обязательное поле']"
                />
                
                <v-select
                  v-model="shopFormData.city"
                  :items="shopCities"
                  item-title="name"
                  item-value="name"
                  label="Город"
                  density="compact"
                  variant="outlined"
                  rounded="lg"
                  :rules="[v => !!v || 'Обязательное поле']"
                />
                
                <v-text-field
                  v-model="shopFormData.address"
                  label="Адрес"
                  density="compact"
                  variant="outlined"
                  rounded="lg"
                  placeholder="ул. Примерная, 123"
                />
                
                <v-text-field
                  v-model="shopFormData.opening_hours"
                  label="Режим работы"
                  density="compact"
                  variant="outlined"
                  rounded="lg"
                  placeholder="Пн-Пт: 10:00-21:00"
                  :rules="[v => !!v || 'Обязательное поле']"
                />
              </div>
            </div>
            
            <!-- Социальные ссылки -->
            <div class="shop-modal__socials-section">
              <h4 class="shop-modal__section-title">
                <Icon name="solar:link-outline" />
                Социальные ссылки
              </h4>
              
              <div class="shop-modal__social-fields">
                <v-text-field
                  v-model="shopFormData.instagram"
                  label="Instagram"
                  density="compact"
                  variant="outlined"
                  rounded="lg"
                  placeholder="ketroy_almaty или полная ссылка"
                >
                  <template #prepend-inner>
                    <svg class="shop-modal__social-icon" viewBox="0 0 24 24" width="20" height="20">
                      <defs>
                        <linearGradient id="instagram-gradient" x1="0%" y1="100%" x2="100%" y2="0%">
                          <stop offset="0%" style="stop-color:#FCAF45"/>
                          <stop offset="25%" style="stop-color:#F77737"/>
                          <stop offset="50%" style="stop-color:#F56040"/>
                          <stop offset="75%" style="stop-color:#C13584"/>
                          <stop offset="100%" style="stop-color:#833AB4"/>
                        </linearGradient>
                      </defs>
                      <path fill="url(#instagram-gradient)" d="M7.8 2h8.4C19.4 2 22 4.6 22 7.8v8.4a5.8 5.8 0 0 1-5.8 5.8H7.8C4.6 22 2 19.4 2 16.2V7.8A5.8 5.8 0 0 1 7.8 2m-.2 2A3.6 3.6 0 0 0 4 7.6v8.8C4 18.39 5.61 20 7.6 20h8.8a3.6 3.6 0 0 0 3.6-3.6V7.6C20 5.61 18.39 4 16.4 4H7.6m9.65 1.5a1.25 1.25 0 0 1 1.25 1.25A1.25 1.25 0 0 1 17.25 8A1.25 1.25 0 0 1 16 6.75a1.25 1.25 0 0 1 1.25-1.25M12 7a5 5 0 0 1 5 5a5 5 0 0 1-5 5a5 5 0 0 1-5-5a5 5 0 0 1 5-5m0 2a3 3 0 0 0-3 3a3 3 0 0 0 3 3a3 3 0 0 0 3-3a3 3 0 0 0-3-3Z"/>
                    </svg>
                  </template>
                </v-text-field>
                
                <v-text-field
                  v-model="shopFormData.whatsapp"
                  label="WhatsApp"
                  density="compact"
                  variant="outlined"
                  rounded="lg"
                  placeholder="+7 777 123 45 67"
                >
                  <template #prepend-inner>
                    <Icon name="mdi:whatsapp" class="shop-modal__social-icon shop-modal__social-icon--whatsapp" />
                  </template>
                </v-text-field>
                
                <v-text-field
                  v-model="shopFormData.two_gis_address"
                  label="2GIS ссылка"
                  density="compact"
                  variant="outlined"
                  rounded="lg"
                  placeholder="https://2gis.kz/almaty/..."
                >
                  <template #prepend-inner>
                    <Icon name="mdi:map-marker" class="shop-modal__social-icon shop-modal__social-icon--2gis" />
                  </template>
                </v-text-field>
              </div>
            </div>
            
            <!-- Статус -->
            <div class="shop-modal__status-section">
              <v-switch
                v-model="shopFormData.is_active"
                label="Магазин активен"
                color="success"
                hide-details
              />
            </div>
          </v-form>
        </v-card-text>
        
        <v-card-actions class="shop-modal__actions">
          <v-btn variant="text" @click="closeShopModal">Отмена</v-btn>
          <v-spacer />
          <v-btn 
            color="primary" 
            variant="flat" 
            rounded="lg"
            :loading="savingShop"
            @click="saveShop"
          >
            {{ editingShop ? 'Сохранить' : 'Создать' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Modal: Управление городами -->
    <v-dialog v-model="showCitiesModal" max-width="550" persistent>
      <v-card rounded="xl" class="cities-modal">
        <v-card-title class="cities-modal__title">
          <Icon name="ph:city" />
          Управление городами
        </v-card-title>
        <v-card-text class="cities-modal__content">
          <!-- Форма добавления нового города -->
          <div class="cities-modal__add-form">
            <div class="cities-modal__add-fields">
              <v-text-field
                v-model="newCityName"
                density="compact"
                variant="outlined"
                placeholder="Название города..."
                rounded="lg"
                hide-details
                class="cities-modal__input"
                @keyup.enter="focusPhoneInput"
              />
              <v-text-field
                ref="newCityPhoneInput"
                v-model="newCityPhone"
                density="compact"
                variant="outlined"
                placeholder="Телефон..."
                rounded="lg"
                hide-details
                class="cities-modal__input cities-modal__input--phone"
                @keyup.enter="addCity"
              />
            </div>
            <v-btn
              color="primary"
              variant="flat"
              rounded="lg"
              :loading="cityLoading"
              :disabled="!newCityName.trim() || cityLoading"
              @click="addCity"
            >
              <Icon name="mdi:plus" />
            </v-btn>
          </div>
          
          <!-- Список городов -->
          <div class="cities-modal__list-container">
            <div v-if="citiesLoading" class="cities-modal__loading">
              <v-progress-circular indeterminate :size="32" :width="3" />
              <span>Загрузка...</span>
            </div>
            <div v-else-if="!citiesList.length" class="cities-modal__empty">
              <Icon name="solar:city-outline" />
              <span>Городов пока нет</span>
            </div>
            <div v-else class="cities-modal__list">
              <div 
                v-for="(city, index) in citiesList" 
                :key="city.name + index" 
                class="cities-modal__item"
                :class="{ 'cities-modal__item--editing': editingCityIndex === index }"
              >
                <!-- Режим просмотра -->
                <template v-if="editingCityIndex !== index">
                  <div class="cities-modal__item-info">
                    <span class="cities-modal__item-name">{{ city.name }}</span>
                    <span class="cities-modal__item-phone">{{ city.phone || 'Нет телефона' }}</span>
                  </div>
                  <div class="cities-modal__item-actions">
                    <v-btn 
                      icon 
                      size="small" 
                      variant="text" 
                      @click.stop="startEditCity(index)"
                    >
                      <Icon name="solar:pen-outline" size="18" />
                    </v-btn>
                    <v-btn 
                      icon 
                      size="small" 
                      variant="text" 
                      color="error" 
                      :loading="deletingCityIndex === index" 
                      @click.stop="deleteCity(index)"
                    >
                      <Icon name="mdi:delete-outline" size="18" />
                    </v-btn>
                  </div>
                </template>
                
                <!-- Режим редактирования -->
                <template v-else>
                  <div class="cities-modal__item-edit">
                    <input
                      ref="cityEditNameInput"
                      v-model="editingCityName"
                      type="text"
                      class="cities-modal__edit-input"
                      placeholder="Название города..."
                    />
                    <input
                      v-model="editingCityPhone"
                      type="text"
                      class="cities-modal__edit-input cities-modal__edit-input--phone"
                      placeholder="Телефон..."
                      @keydown.enter="saveEditCity(index)"
                    />
                  </div>
                  <div class="cities-modal__item-actions">
                    <v-btn 
                      icon 
                      size="small" 
                      variant="text"
                      color="success"
                      @click.stop="saveEditCity(index)"
                    >
                      <Icon name="mdi:check" size="18" />
                    </v-btn>
                    <v-btn 
                      icon 
                      size="small" 
                      variant="text" 
                      @click.stop="cancelEditCity"
                    >
                      <Icon name="mdi:close" size="18" />
                    </v-btn>
                  </div>
                </template>
              </div>
            </div>
          </div>
        </v-card-text>
        <v-card-actions class="cities-modal__actions">
          <v-btn variant="text" @click="closeCitiesModal">Закрыть</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Модальное окно уведомления при публикации новости -->
    <news-publish-notification-modal 
      v-model="showPublishNotificationModal"
      @confirm="onPublishNotificationConfirm"
    />
  </section>
</template>

<script setup lang="ts">
import { AdminEnums } from '~/types/enums';
import { useConfirm } from '~/composables/useConfirm';
import { t, useNewsPublishNotification } from '~/composables';
import Cropper from 'cropperjs';
import 'cropperjs/dist/cropper.css';

const { confirm } = useConfirm();
const route = useRoute();
const router = useRouter();
const layoutStore = useLayoutStore();
const tabItems: Types.Tab[] = Object.values(AdminEnums.ContentItems).map((i) => {
  return { title: () => t(`admin.content.${i}`), value: i };
});
const list = ref<Types.List>([]);
const loading = ref(true);

const showAddButton = computed(() => {
  return true;
});

// ============== КАТЕГОРИИ ==============
const showCategoriesModal = ref(false);
const categories = ref<{ id?: number; name: string }[]>([]);
const categoriesLoading = ref(false);
const categoryLoading = ref(false);
const newCategoryName = ref('');
const deletingCategoryId = ref<number | null>(null);

// Drag & Drop для категорий
const draggingCategoryIndex = ref<number | null>(null);
const isDraggingCategory = ref(false);
let lastCategorySwapTime = 0;
const CATEGORY_SWAP_THROTTLE = 150;

const onCategoryDragStart = (index: number, event: DragEvent) => {
  draggingCategoryIndex.value = index;
  isDraggingCategory.value = true;
  lastCategorySwapTime = 0;
  if (event.dataTransfer) {
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', String(index));
  }
  const target = event.target as HTMLElement | null;
  if (target) {
    setTimeout(() => {
      target.style.opacity = '0.5';
    }, 0);
  }
};

const onCategoryDragOver = (index: number, event: DragEvent) => {
  event.preventDefault();
  if (event.dataTransfer) {
    event.dataTransfer.dropEffect = 'move';
  }
  const sourceIndex = draggingCategoryIndex.value;
  if (sourceIndex === null || sourceIndex === index) return;
  
  const now = Date.now();
  if (now - lastCategorySwapTime < CATEGORY_SWAP_THROTTLE) return;
  lastCategorySwapTime = now;
  
  const items = [...categories.value];
  const [removed] = items.splice(sourceIndex, 1);
  items.splice(index, 0, removed);
  categories.value = items;
  draggingCategoryIndex.value = index;
};

const onCategoryDrop = async (event: DragEvent) => {
  event.preventDefault();
  await saveCategoriesOrder();
};

const onCategoryDragEnd = (event: DragEvent) => {
  if (event.target instanceof HTMLElement) {
    event.target.style.opacity = '';
  }
  draggingCategoryIndex.value = null;
  isDraggingCategory.value = false;
  lastCategorySwapTime = 0;
};

const saveCategoriesOrder = async () => {
  try {
    const orderedCategories = categories.value.map((cat, index) => ({
      id: index + 1,
      name: cat.name
    }));
    await api.categories.add(orderedCategories);
    categories.value = orderedCategories;
    showToaster('success', 'Порядок категорий сохранён');
  } catch (err) {
    console.error('Failed to save categories order:', err);
    showToaster('error', 'Ошибка сохранения порядка');
    await loadCategories();
  }
};

// Редактирование категорий
const editingCategoryIndex = ref<number | null>(null);
const editingCategoryName = ref('');
const categoryEditInputRefs = ref<Record<number, HTMLInputElement | null>>({});

const startEditCategory = (index: number) => {
  editingCategoryIndex.value = index;
  editingCategoryName.value = categories.value[index].name;
  nextTick(() => {
    const input = categoryEditInputRefs.value[index];
    if (input) {
      input.focus();
      input.select();
    }
  });
};

const saveEditCategory = async (index: number) => {
  const newName = editingCategoryName.value.trim();
  if (!newName) {
    cancelEditCategory();
    return;
  }
  
  categories.value[index].name = newName;
  editingCategoryIndex.value = null;
  editingCategoryName.value = '';
  
  try {
    const orderedCategories = categories.value.map((cat, i) => ({
      id: i + 1,
      name: cat.name
    }));
    await api.categories.add(orderedCategories);
    showToaster('success', 'Категория обновлена');
  } catch (err) {
    console.error('Failed to save category:', err);
    showToaster('error', 'Ошибка сохранения');
    await loadCategories();
  }
};

const cancelEditCategory = () => {
  editingCategoryIndex.value = null;
  editingCategoryName.value = '';
};

const setCategoryEditInputRef = (el: any, index: number) => {
  categoryEditInputRefs.value[index] = el as HTMLInputElement;
};

const openCategoriesModal = async () => {
  showCategoriesModal.value = true;
  await loadCategories();
};

const closeCategoriesModal = () => {
  showCategoriesModal.value = false;
  newCategoryName.value = '';
};

const loadCategories = async () => {
  categoriesLoading.value = true;
  try {
    const response = await api.categories.getAll();
    if (response && Array.isArray(response)) {
      categories.value = response;
    }
  } catch (err) {
    console.error('Failed to load categories:', err);
    categories.value = [];
  } finally {
    categoriesLoading.value = false;
  }
};

const addCategory = async () => {
  if (!newCategoryName.value.trim()) return;
  
  categoryLoading.value = true;
  try {
    const updatedCategories = [...categories.value, { name: newCategoryName.value.trim() }];
    const response = await api.categories.add(updatedCategories);
    if (response?.message) showToaster('success', String(response.message));
    newCategoryName.value = '';
    await loadCategories();
  } catch (err) {
    console.error('Failed to add category:', err);
    showToaster('error', 'Ошибка при добавлении категории');
  } finally {
    categoryLoading.value = false;
  }
};

const deleteCategory = async (category: { id?: number; name: string }) => {
  deletingCategoryId.value = category.id ?? null;
  try {
    const updatedCategories = categories.value.filter(item => item.name !== category.name);
    const response = await api.categories.add(updatedCategories);
    if (response?.message) showToaster('success', String(response.message));
    await loadCategories();
  } catch (err) {
    console.error('Failed to delete category:', err);
    showToaster('error', 'Ошибка при удалении категории');
  } finally {
    deletingCategoryId.value = null;
  }
};

// ============== ИСТОРИИ ==============
const loadingGroups = ref(false);
const savingGroup = ref(false);
const savingStory = ref(false);
const deletingStories = ref(false);
const groups = ref<any[]>([]);
const selectedGroup = ref<any>(null);
const isNewGroup = ref(false);
const selectedStoryIds = ref<number[]>([]);

// ============== DRAG & DROP ==============
const draggingGroupIndex = ref<number | null>(null);
const draggingStoryIndex = ref<number | null>(null);
const savingOrder = ref(false);
const isDraggingGroup = ref(false);
const isDraggingStory = ref(false);
let lastGroupSwapTime = 0;
let lastStorySwapTime = 0;
const SWAP_THROTTLE = 150; // мс между перестановками

// Drag & Drop для групп с живым перестроением
const onGroupDragStart = (index: number, event: DragEvent) => {
  draggingGroupIndex.value = index;
  isDraggingGroup.value = true;
  lastGroupSwapTime = 0;
  
  if (event.dataTransfer) {
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', String(index));
  }
  const target = event.target as HTMLElement | null;
  if (target) {
    setTimeout(() => {
      target.style.opacity = '0.5';
    }, 0);
  }
};

const onGroupDragOver = (index: number, event: DragEvent) => {
  event.preventDefault();
  if (event.dataTransfer) {
    event.dataTransfer.dropEffect = 'move';
  }
  
  const sourceIndex = draggingGroupIndex.value;
  if (sourceIndex === null || sourceIndex === index) return;
  
  // Throttle - не чаще чем раз в SWAP_THROTTLE мс
  const now = Date.now();
  if (now - lastGroupSwapTime < SWAP_THROTTLE) return;
  lastGroupSwapTime = now;
  
  // Живое перестроение
  const items = [...groups.value];
  const [removed] = items.splice(sourceIndex, 1);
  items.splice(index, 0, removed);
  groups.value = items;
  draggingGroupIndex.value = index;
};

const onGroupDrop = async (event: DragEvent) => {
  event.preventDefault();
  await saveGroupsOrder();
};

const onGroupDragEnd = (event: DragEvent) => {
  if (event.target instanceof HTMLElement) {
    event.target.style.opacity = '';
  }
  draggingGroupIndex.value = null;
  isDraggingGroup.value = false;
  lastGroupSwapTime = 0;
};

const saveGroupsOrder = async () => {
  savingOrder.value = true;
  try {
    const reorderData = groups.value.map((group, index) => ({
      id: group.id,
      sort_order: index,
    }));
    
    await api.actuals.reorder(reorderData);
    showToaster('success', 'Порядок групп сохранён');
  } catch (err) {
    console.error('Failed to save groups order:', err);
    showToaster('error', 'Ошибка сохранения порядка');
    await loadStoriesData();
  } finally {
    savingOrder.value = false;
  }
};

// Drag & Drop для историй с живым перестроением
const onStoryDragStart = (index: number, event: DragEvent) => {
  draggingStoryIndex.value = index;
  isDraggingStory.value = true;
  lastStorySwapTime = 0;
  
  if (event.dataTransfer) {
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', String(index));
  }
  const target = event.target as HTMLElement | null;
  if (target) {
    setTimeout(() => {
      target.style.opacity = '0.4';
      target.style.transform = 'scale(1.05)';
    }, 0);
  }
};

const onStoryDragOver = (index: number, event: DragEvent) => {
  event.preventDefault();
  if (event.dataTransfer) {
    event.dataTransfer.dropEffect = 'move';
  }
  
  const sourceIndex = draggingStoryIndex.value;
  if (sourceIndex === null || sourceIndex === index || !selectedGroup.value?.stories) return;
  
  // Throttle - не чаще чем раз в SWAP_THROTTLE мс
  const now = Date.now();
  if (now - lastStorySwapTime < SWAP_THROTTLE) return;
  lastStorySwapTime = now;
  
  // Живое перестроение
  const items = [...selectedGroup.value.stories];
  const [removed] = items.splice(sourceIndex, 1);
  items.splice(index, 0, removed);
  selectedGroup.value.stories = items;
  
  // Обновляем также в groups
  const groupIndex = groups.value.findIndex(g => g.name === selectedGroup.value.name);
  if (groupIndex !== -1) {
    groups.value[groupIndex].stories = items;
  }
  
  draggingStoryIndex.value = index;
};

const onStoryDrop = async (event: DragEvent) => {
  event.preventDefault();
  await saveStoriesOrder();
};

const onStoryDragEnd = (event: DragEvent) => {
  if (event.target instanceof HTMLElement) {
    event.target.style.opacity = '';
    event.target.style.transform = '';
  }
  draggingStoryIndex.value = null;
  isDraggingStory.value = false;
  lastStorySwapTime = 0;
};

const saveStoriesOrder = async () => {
  if (!selectedGroup.value?.stories?.length) return;
  
  savingOrder.value = true;
  try {
    const reorderData = selectedGroup.value.stories.map((story: any, index: number) => ({
      id: story.id,
      sort_order: index,
    }));
    
    await api.histories.reorder(reorderData);
    showToaster('success', 'Порядок историй сохранён');
  } catch (err) {
    console.error('Failed to save stories order:', err);
    showToaster('error', 'Ошибка сохранения порядка');
    await loadStoriesData();
  } finally {
    savingOrder.value = false;
  }
};

// Inline создание группы
const showInlineCreate = ref(false);
const savingInlineGroup = ref(false);
const inlineNewGroup = ref({ name: '', cover: null as string | null });
const inlineCoverInput = ref<HTMLInputElement | null>(null);
const inlineNameInput = ref<HTMLInputElement | null>(null);

const storyDialog = ref(false);
const editingStory = ref<any>({
  type: 'image',
  name: '',
  city: 'Все',
  is_active: true,
  file_path: null
});
const cities = ref<any[]>([]);

const coverInput = ref<HTMLInputElement | null>(null);
const mediaInput = ref<HTMLInputElement | null>(null);

// ============== ДИАЛОГИ КРОПА ИЗОБРАЖЕНИЙ ==============
const coverCropDialog = ref(false);
const coverCropImageUrl = ref<string | null>(null);
const coverCropper = ref<Cropper | null>(null);
const coverCropImageEl = ref<HTMLImageElement | null>(null);
const isInlineCoverCrop = ref(false); // Флаг для определения режима inline кропа

const mediaCropDialog = ref(false);
const mediaCropImageUrl = ref<string | null>(null);
const mediaCropper = ref<Cropper | null>(null);
const mediaCropImageEl = ref<HTMLImageElement | null>(null);

// Системные группы теперь определяются по полю is_system из БД
const isSystemGroup = computed(() => selectedGroup.value?.is_system === true);

// ============== НОВОСТИ ==============
const loadingNews = ref(false);
const newsList = ref<any[]>([]);
const archivedNewsList = ref<any[]>([]);
const newsSearch = ref('');
const selectedNewsIds = ref<number[]>([]);
const deletingNews = ref(false);
const showNewsArchive = ref(false);
const archivingNews = ref(false);
const isModeSwitching = ref(false);

// Модальное окно уведомления при публикации
const showPublishNotificationModal = ref(false);
const pendingNewsToggle = ref<{ news: any; newState: boolean } | null>(null);
const { shouldShowNotification, confirmPublish, rejectPublish } = useNewsPublishNotification();

// Drag & Drop для новостей
const draggingNewsIndex = ref<number | null>(null);
const isDraggingNews = ref(false);
const savingNewsOrder = ref(false);
let lastNewsSwapTime = 0;
const NEWS_SWAP_THROTTLE = 150; // мс между перестановками

const onNewsDragStart = (index: number, event: DragEvent) => {
  draggingNewsIndex.value = index;
  isDraggingNews.value = true;
  lastNewsSwapTime = 0;
  if (event.dataTransfer) {
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', String(index));
  }
  const target = event.target as HTMLElement | null;
  if (target) {
    setTimeout(() => {
      target.style.opacity = '0.5';
    }, 0);
  }
};

const onNewsDragOver = (index: number, event: DragEvent) => {
  event.preventDefault();
  if (event.dataTransfer) {
    event.dataTransfer.dropEffect = 'move';
  }
  const sourceIndex = draggingNewsIndex.value;
  if (sourceIndex === null || sourceIndex === index) return;
  
  // Throttle - не чаще чем раз в NEWS_SWAP_THROTTLE мс
  const now = Date.now();
  if (now - lastNewsSwapTime < NEWS_SWAP_THROTTLE) return;
  lastNewsSwapTime = now;
  
  // Живое перестроение
  const items = [...newsList.value];
  const [removed] = items.splice(sourceIndex, 1);
  items.splice(index, 0, removed);
  newsList.value = items;
  draggingNewsIndex.value = index;
};

const onNewsDrop = async (event: DragEvent) => {
  event.preventDefault();
  await saveNewsOrder();
};

const onNewsDragEnd = (event: DragEvent) => {
  if (event.target instanceof HTMLElement) {
    event.target.style.opacity = '';
  }
  draggingNewsIndex.value = null;
  isDraggingNews.value = false;
  lastNewsSwapTime = 0;
};

const saveNewsOrder = async () => {
  savingNewsOrder.value = true;
  try {
    const reorderData = newsList.value.map((news, index) => ({
      id: news.id,
      sort_order: index,
    }));
    await api.news.reorder(reorderData);
    showToaster('success', 'Порядок новостей сохранён');
  } catch (err) {
    console.error('Failed to save news order:', err);
    showToaster('error', 'Ошибка сохранения порядка');
    await loadNewsData();
  } finally {
    savingNewsOrder.value = false;
  }
};

const filteredNews = computed(() => {
  const sourceList = showNewsArchive.value ? archivedNewsList.value : newsList.value;
  if (!newsSearch.value) return sourceList;
  const search = newsSearch.value.toLowerCase().trim();
  return sourceList.filter(news => 
    news.name?.toLowerCase().includes(search)
  );
});

const loadNewsData = async () => {
  loadingNews.value = true;
  try {
    const response = await api.news.getAll();
    const items = Array.isArray(response) ? response : (response?.data || []);
    
    newsList.value = items.map((news: any) => ({
      id: news.id,
      name: news.name,
      image: news.blocks?.[0]?.media_path || news.file_path,
      excerpt: extractExcerpt(news.blocks),
      category: news.category,
      is_active: news.is_active ?? true,
      created_at: news.created_at,
    }));
  } catch (err) {
    console.error('Failed to load news:', err);
    newsList.value = [];
  } finally {
    loadingNews.value = false;
  }
};

const loadArchivedNews = async () => {
  loadingNews.value = true;
  try {
    const response = await api.news.getArchived();
    const items = Array.isArray(response) ? response : (response?.data || []);
    
    archivedNewsList.value = items.map((news: any) => ({
      id: news.id,
      name: news.name,
      image: news.blocks?.[0]?.media_path || news.file_path,
      excerpt: extractExcerpt(news.blocks),
      category: news.category,
      is_active: news.is_active ?? true,
      created_at: news.created_at,
    }));
  } catch (err) {
    console.error('Failed to load archived news:', err);
    archivedNewsList.value = [];
  } finally {
    loadingNews.value = false;
  }
};

// Переключение режима архива
const toggleNewsArchive = async () => {
  isModeSwitching.value = true;
  showNewsArchive.value = !showNewsArchive.value;
  selectedNewsIds.value = [];
  newsSearch.value = '';
  
  if (showNewsArchive.value && archivedNewsList.value.length === 0) {
    await loadArchivedNews();
  }
  
  // Сбрасываем флаг после завершения анимации
  setTimeout(() => {
    isModeSwitching.value = false;
  }, 350);
};

const extractExcerpt = (blocks: any[]): string => {
  if (!blocks?.length) return '';
  const textBlock = blocks.find(b => b.type === 'text' && b.content);
  if (!textBlock?.content) return '';
  // Убираем HTML теги и обрезаем
  const text = textBlock.content.replace(/<[^>]+>/g, '').trim();
  return text.length > 120 ? text.substring(0, 120) + '...' : text;
};

const formatNewsDate = (date: string) => {
  if (!date) return '';
  const d = new Date(date);
  return d.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short', year: 'numeric' });
};

const formatNewsCategory = (category: any): string => {
  if (!category) return '';
  
  // Если это уже массив
  if (Array.isArray(category)) {
    return category.filter(c => c && c !== 'Все').join(', ');
  }
  
  // Если это строка
  if (typeof category === 'string') {
    let value = category.trim();
    
    // Пробуем распарсить JSON (может быть двойная сериализация)
    let attempts = 0;
    while (attempts < 3 && typeof value === 'string' && value.startsWith('[')) {
      try {
        const parsed = JSON.parse(value);
        if (Array.isArray(parsed)) {
          // Проверяем, не содержит ли массив строку-JSON
          if (parsed.length === 1 && typeof parsed[0] === 'string' && parsed[0].startsWith('[')) {
            value = parsed[0];
            attempts++;
            continue;
          }
          return parsed.filter(c => c && c !== 'Все').join(', ');
        }
        break;
      } catch {
        break;
      }
    }
    
    // Убираем лишние кавычки и скобки если остались
    return value.replace(/^\[|\]$/g, '').replace(/^"|"$/g, '').replace(/",\s*"/g, ', ');
  }
  
  return String(category);
};

const toggleNewsActive = async (news: any) => {
  const newState = !news.is_active;
  
  // Если нужно активировать новость, проверяем нужно ли показывать модальное окно
  if (newState && shouldShowNotification(news.id)) {
    pendingNewsToggle.value = { news, newState };
    showPublishNotificationModal.value = true;
    return;
  }
  
  // Иначе сразу обновляем
  try {
    await api.news.quickUpdate(news.id, { is_active: newState });
    news.is_active = newState;
    showToaster('success', newState ? 'Новость опубликована' : 'Новость скрыта');
  } catch (err) {
    console.error('Failed to toggle news:', err);
    showToaster('error', 'Ошибка обновления');
  }
};

const onPublishNotificationConfirm = async (result: { sendNotification: boolean; dontAskAgain: boolean }) => {
  const { sendNotification, dontAskAgain } = result;
  
  if (!pendingNewsToggle.value) return;
  
  const { news, newState } = pendingNewsToggle.value;
  
  try {
    // Подготавливаем данные для отправки уведомления с учётом фильтров таргетирования
    const updateData: any = { is_active: newState };
    
    if (sendNotification) {
      updateData.send_notification = true;
      // Передаём фильтры таргетирования вместе с уведомлением
      updateData.target_cities = news.city && news.city !== 'Все' ? (Array.isArray(news.city) ? news.city : [news.city]) : undefined;
      updateData.target_categories = news.category && news.category !== 'Все' ? (Array.isArray(news.category) ? news.category : [news.category]) : undefined;
      updateData.target_shoe_size = news.shoe_size || undefined;
      updateData.target_clothing_size = news.clothing_size || undefined;
      
      console.log('📢 Отправка уведомления с фильтрами:', { 
        newsId: news.id, 
        newsName: news.name,
        filters: {
          target_cities: updateData.target_cities,
          target_categories: updateData.target_categories,
          target_shoe_size: updateData.target_shoe_size,
          target_clothing_size: updateData.target_clothing_size
        }
      });
    } else {
      console.log('🔇 Уведомление НЕ отправляется - пользователь выбрал "Нет"', { newsId: news.id, newsName: news.name });
    }
    
    // Отправляем запрос с флагом отправки уведомления и фильтрами
    console.log('📤 Отправляем запрос на сервер:', updateData);
    await api.news.quickUpdate(news.id, updateData);
    news.is_active = newState;
    
    // Сохраняем выбор пользователя если нужно
    if (dontAskAgain) {
      if (sendNotification) {
        confirmPublish(true);
      } else {
        rejectPublish(true);
      }
    }
    
    const notificationStatus = sendNotification ? ' ✓ с уведомлением' : '';
    showToaster('success', newState ? 'Новость опубликована' + notificationStatus : 'Новость скрыта');
  } catch (err) {
    console.error('Failed to toggle news:', err);
    showToaster('error', 'Ошибка обновления');
  } finally {
    pendingNewsToggle.value = null;
    showPublishNotificationModal.value = false;
  }
};

// Переход к редактированию новости по клику на карточку
const navigateToNewsEdit = (news: any, event: MouseEvent) => {
  // Не переходим, если перетаскиваем или если клик был на интерактивном элементе
  if (isDraggingNews.value) return;
  
  const target = event.target as HTMLElement;
  // Проверяем, что клик не на кнопке, свитче, чекбоксе или ссылке
  const isInteractiveElement = target.closest('button, a, .v-switch, .news-manager__card-checkbox, .news-manager__card-actions');
  if (isInteractiveElement) return;
  
  // Переходим к редактированию
  navigateTo({ name: 'content-tab@id', params: { tab: 'news', id: news.id } });
};

const deleteNews = async (news: any) => {
  const confirmed = await confirm({
    title: 'Удаление новости',
    message: `Удалить новость "${news.name}"?`,
    confirmText: 'Удалить',
    type: 'danger',
  });
  if (!confirmed) return;
  
  try {
    await api.news.delete(news.id);
    newsList.value = newsList.value.filter(n => n.id !== news.id);
    showToaster('success', 'Новость удалена');
  } catch (err) {
    console.error('Failed to delete news:', err);
    showToaster('error', 'Ошибка удаления');
  }
};

// Выбор новостей для массового удаления
const toggleNewsSelection = (newsId: number) => {
  const idx = selectedNewsIds.value.indexOf(newsId);
  if (idx === -1) {
    selectedNewsIds.value.push(newsId);
  } else {
    selectedNewsIds.value.splice(idx, 1);
  }
};

// Массовое удаление выбранных новостей (только из архива)
const deleteSelectedNews = async () => {
  if (!selectedNewsIds.value.length) return;
  
  const count = selectedNewsIds.value.length;
  const confirmed = await confirm({
    title: 'Удаление новостей',
    message: `Удалить ${count} ${count === 1 ? 'новость' : count < 5 ? 'новости' : 'новостей'} навсегда?`,
    confirmText: 'Удалить',
    type: 'danger',
  });
  if (!confirmed) return;
  
  deletingNews.value = true;
  try {
    const idsToDelete = [...selectedNewsIds.value];
    await api.news.deleteMany(idsToDelete);
    archivedNewsList.value = archivedNewsList.value.filter(n => !idsToDelete.includes(n.id));
    selectedNewsIds.value = [];
    showToaster('success', 'Новости удалены');
  } catch (err) {
    console.error('Failed to delete news:', err);
    showToaster('error', 'Ошибка удаления');
  } finally {
    deletingNews.value = false;
  }
};

// Архивация одной новости
const archiveNews = async (news: any) => {
  try {
    // При архивации отключаем новость
    await api.news.archive(news.id);
    // Создаём копию с отключённым статусом
    const archivedNews = { ...news, is_active: false };
    // Удаляем из основного списка
    newsList.value = newsList.value.filter(n => n.id !== news.id);
    // Добавляем в архив с деактивированным статусом
    archivedNewsList.value.unshift(archivedNews);
    showToaster('success', 'Новость перемещена в архив и деактивирована');
  } catch (err) {
    console.error('Failed to archive news:', err);
    showToaster('error', 'Ошибка архивации');
  }
};

// Массовая архивация выбранных новостей
const archiveSelectedNews = async () => {
  if (!selectedNewsIds.value.length) return;
  
  const count = selectedNewsIds.value.length;
  const confirmed = await confirm({
    title: 'Архивация новостей',
    message: `Переместить ${count} ${count === 1 ? 'новость' : count < 5 ? 'новости' : 'новостей'} в архив?`,
    confirmText: 'В архив',
    type: 'warning',
  });
  if (!confirmed) return;
  
  archivingNews.value = true;
  try {
    const idsToArchive = [...selectedNewsIds.value];
    // Сохраняем новости для добавления в архив с деактивированным статусом
    const newsToArchive = newsList.value.filter(n => idsToArchive.includes(n.id)).map(n => ({
      ...n,
      is_active: false
    }));
    await api.news.archiveMany(idsToArchive);
    // Удаляем из основного списка
    newsList.value = newsList.value.filter(n => !idsToArchive.includes(n.id));
    // Добавляем в архив с деактивированным статусом
    archivedNewsList.value.unshift(...newsToArchive);
    selectedNewsIds.value = [];
    showToaster('success', 'Новости перемещены в архив и деактивированы');
  } catch (err) {
    console.error('Failed to archive news:', err);
    showToaster('error', 'Ошибка архивации');
  } finally {
    archivingNews.value = false;
  }
};

// Восстановление из архива
const restoreNews = async (news: any) => {
  try {
    await api.news.restore(news.id);
    // Удаляем из архива
    archivedNewsList.value = archivedNewsList.value.filter(n => n.id !== news.id);
    // Добавляем обратно в основной список
    newsList.value.unshift({ ...news });
    showToaster('success', 'Новость восстановлена');
  } catch (err) {
    console.error('Failed to restore news:', err);
    showToaster('error', 'Ошибка восстановления');
  }
};

// Удаление из архива (безвозвратное)
const deleteNewsFromArchive = async (news: any) => {
  const confirmed = await confirm({
    title: 'Удаление новости',
    message: `Удалить новость "${news.name}" навсегда? Это действие нельзя отменить.`,
    confirmText: 'Удалить навсегда',
    type: 'danger',
  });
  if (!confirmed) return;
  
  try {
    await api.news.delete(news.id);
    archivedNewsList.value = archivedNewsList.value.filter(n => n.id !== news.id);
    showToaster('success', 'Новость удалена');
  } catch (err) {
    console.error('Failed to delete news:', err);
    showToaster('error', 'Ошибка удаления');
  }
};

// ============== МАГАЗИНЫ ==============
const loadingShops = ref(false);
const shopsList = ref<any[]>([]);
const shopsSearch = ref('');
const showShopModal = ref(false);
const editingShop = ref<any>(null);
const savingShop = ref(false);
const shopCities = ref<any[]>([]);
const shopImageInput = ref<HTMLInputElement | null>(null);
const shopForm = ref<any>(null);

const shopFormData = ref({
  name: '',
  city: '',
  address: '',
  opening_hours: '',
  instagram: '',
  two_gis_address: '',
  whatsapp: '',
  image: '',
  is_active: true,
});

const filteredShops = computed(() => {
  if (!shopsSearch.value) return shopsList.value;
  const search = shopsSearch.value.toLowerCase();
  return shopsList.value.filter(shop => 
    shop.name?.toLowerCase().includes(search) ||
    shop.city?.toLowerCase().includes(search) ||
    shop.address?.toLowerCase().includes(search)
  );
});

const loadShopsData = async () => {
  loadingShops.value = true;
  try {
    const [shopsResponse, citiesResponse] = await Promise.all([
      api.shops.getAll(),
      api.cities.getAll()
    ]);
    
    const shops = Array.isArray(shopsResponse) ? shopsResponse : (shopsResponse as any)?.data || [];
    const cities = Array.isArray(citiesResponse) ? citiesResponse : (citiesResponse as any)?.data || [];
    
    shopsList.value = shops.map((shop: any) => ({
      ...shop,
      file_path: shop.file_path || ''
    }));
    
    shopCities.value = cities || [];
  } catch (err) {
    console.error('Failed to load shops:', err);
    shopsList.value = [];
  } finally {
    loadingShops.value = false;
  }
};

const openShopModal = (shop?: any) => {
  if (shop) {
    editingShop.value = shop;
    shopFormData.value = {
      name: shop.name || '',
      city: shop.city || '',
      address: shop.address || '',
      opening_hours: shop.opening_hours || '',
      instagram: shop.instagram || '',
      two_gis_address: shop.two_gis_address || '',
      whatsapp: shop.whatsapp || '',
      image: shop.file_path || '',
      is_active: shop.is_active ?? true,
    };
  } else {
    editingShop.value = null;
    shopFormData.value = {
      name: '',
      city: shopCities.value[0]?.name || '',
      address: '',
      opening_hours: '',
      instagram: '',
      two_gis_address: '',
      whatsapp: '',
      image: '',
      is_active: true,
    };
  }
  showShopModal.value = true;
};

const closeShopModal = () => {
  showShopModal.value = false;
  editingShop.value = null;
};

const triggerShopImageUpload = () => {
  shopImageInput.value?.click();
};

const onShopImageChange = async (event: Event) => {
  const target = event.target as HTMLInputElement;
  const file = target.files?.[0];
  if (!file) return;
  
  // Конвертируем в base64
  const reader = new FileReader();
  reader.onload = (e) => {
    shopFormData.value.image = e.target?.result as string;
  };
  reader.readAsDataURL(file);
  
  // Очистим input для возможности повторного выбора того же файла
  target.value = '';
};

const saveShop = async () => {
  // Простая валидация
  if (!shopFormData.value.name || !shopFormData.value.city || !shopFormData.value.opening_hours) {
    showToaster('error', 'Заполните обязательные поля');
    return;
  }
  
  savingShop.value = true;
  try {
    const payload: any = {
      name: shopFormData.value.name,
      city: shopFormData.value.city,
      address: shopFormData.value.address,
      opening_hours: shopFormData.value.opening_hours,
      instagram: shopFormData.value.instagram,
      two_gis_address: shopFormData.value.two_gis_address,
      whatsapp: shopFormData.value.whatsapp,
      file: shopFormData.value.image,
      is_active: shopFormData.value.is_active,
    };
    
    if (editingShop.value) {
      await api.shops.update(editingShop.value.id, payload as any);
      showToaster('success', 'Магазин обновлён');
    } else {
      await api.shops.add(payload as any);
      showToaster('success', 'Магазин создан');
    }
    
    closeShopModal();
    await loadShopsData();
  } catch (err) {
    console.error('Failed to save shop:', err);
    showToaster('error', 'Ошибка сохранения');
  } finally {
    savingShop.value = false;
  }
};

const deleteShop = async (shop: any) => {
  const confirmed = await confirm({
    title: 'Удалить магазин?',
    message: `Вы уверены, что хотите удалить магазин "${shop.name}"?`,
  });
  
  if (!confirmed) return;
  
  try {
    await api.shops.delete(shop.id);
    shopsList.value = shopsList.value.filter(s => s.id !== shop.id);
    showToaster('success', 'Магазин удалён');
  } catch (err) {
    console.error('Failed to delete shop:', err);
    showToaster('error', 'Ошибка удаления');
  }
};

// ============== ГОРОДА ==============
const showCitiesModal = ref(false);
const citiesList = ref<{ name: string; phone: string }[]>([]);
const citiesLoading = ref(false);
const cityLoading = ref(false);
const newCityName = ref('');
const newCityPhone = ref('');
const deletingCityIndex = ref<number | null>(null);
const editingCityIndex = ref<number | null>(null);
const editingCityName = ref('');
const editingCityPhone = ref('');
const newCityPhoneInput = ref<any>(null);
const cityEditNameInput = ref<HTMLInputElement | null>(null);

const focusPhoneInput = () => {
  nextTick(() => {
    newCityPhoneInput.value?.focus();
  });
};

const openCitiesModal = async () => {
  showCitiesModal.value = true;
  await loadCitiesData();
};

const closeCitiesModal = () => {
  showCitiesModal.value = false;
  newCityName.value = '';
  newCityPhone.value = '';
  editingCityIndex.value = null;
};

const loadCitiesData = async () => {
  citiesLoading.value = true;
  try {
    const response = await api.cities.getAll();
    citiesList.value = Array.isArray(response) ? response : [];
  } catch (err) {
    console.error('Failed to load cities:', err);
    citiesList.value = [];
  } finally {
    citiesLoading.value = false;
  }
};

const addCity = async () => {
  if (!newCityName.value.trim()) return;
  
  cityLoading.value = true;
  try {
    const newCity = {
      name: newCityName.value.trim(),
      phone: newCityPhone.value.trim(),
    };
    
    const updatedCities = [...citiesList.value, newCity];
    await api.cities.add(updatedCities as any);
    
    citiesList.value = updatedCities;
    shopCities.value = updatedCities;
    newCityName.value = '';
    newCityPhone.value = '';
    showToaster('success', 'Город добавлен');
  } catch (err) {
    console.error('Failed to add city:', err);
    showToaster('error', 'Ошибка добавления города');
  } finally {
    cityLoading.value = false;
  }
};

const startEditCity = (index: number) => {
  editingCityIndex.value = index;
  editingCityName.value = citiesList.value[index].name;
  editingCityPhone.value = citiesList.value[index].phone || '';
  nextTick(() => {
    (cityEditNameInput.value as any)?.[0]?.focus();
  });
};

const cancelEditCity = () => {
  editingCityIndex.value = null;
  editingCityName.value = '';
  editingCityPhone.value = '';
};

const saveEditCity = async (index: number) => {
  if (!editingCityName.value.trim()) {
    cancelEditCity();
    return;
  }
  
  try {
    const updatedCities = [...citiesList.value];
    updatedCities[index] = {
      name: editingCityName.value.trim(),
      phone: editingCityPhone.value.trim(),
    };
    
    await api.cities.add(updatedCities as any);
    
    citiesList.value = updatedCities;
    shopCities.value = updatedCities;
    cancelEditCity();
    showToaster('success', 'Город обновлён');
  } catch (err) {
    console.error('Failed to update city:', err);
    showToaster('error', 'Ошибка обновления города');
  }
};

const deleteCity = async (index: number) => {
  const city = citiesList.value[index];
  const confirmed = await confirm({
    title: 'Удалить город?',
    message: `Вы уверены, что хотите удалить город "${city.name}"?`,
  });
  
  if (!confirmed) return;
  
  deletingCityIndex.value = index;
  try {
    const updatedCities = citiesList.value.filter((_, i) => i !== index);
    await api.cities.add(updatedCities as any);
    
    citiesList.value = updatedCities;
    shopCities.value = updatedCities;
    showToaster('success', 'Город удалён');
  } catch (err) {
    console.error('Failed to delete city:', err);
    showToaster('error', 'Ошибка удаления города');
  } finally {
    deletingCityIndex.value = null;
  }
};

// Форматирование ссылок
const formatInstagramUrl = (instagram: string) => {
  if (!instagram) return '';
  if (instagram.startsWith('http')) return instagram;
  // Убираем @ если есть
  const username = instagram.replace('@', '');
  return `https://instagram.com/${username}`;
};

const formatWhatsAppUrl = (phone: string) => {
  if (!phone) return '';
  if (phone.startsWith('http')) return phone;
  // Очищаем номер от лишних символов
  const cleanPhone = phone.replace(/[^\d+]/g, '').replace('+', '');
  return `https://wa.me/${cleanPhone}`;
};

// ============== БАННЕРЫ ==============
const loadingBanners = ref(false);
const banners = ref<any[]>([]);
const previewCity = ref('Все');
const carouselIndex = ref(0);

// Drag & Drop для баннеров
const draggingBannerIndex = ref<number | null>(null);
const isDraggingBanner = ref(false);
const savingBannerOrder = ref(false);
let lastBannerSwapTime = 0;
const BANNER_SWAP_THROTTLE = 150; // мс между перестановками

const onBannerDragStart = (index: number, event: DragEvent) => {
  draggingBannerIndex.value = index;
  isDraggingBanner.value = true;
  lastBannerSwapTime = 0;
  if (event.dataTransfer) {
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', String(index));
  }
  const target = event.target as HTMLElement | null;
  if (target) {
    setTimeout(() => {
      target.style.opacity = '0.5';
    }, 0);
  }
};

const onBannerDragOver = (index: number, event: DragEvent) => {
  event.preventDefault();
  if (event.dataTransfer) {
    event.dataTransfer.dropEffect = 'move';
  }
  const sourceIndex = draggingBannerIndex.value;
  if (sourceIndex === null || sourceIndex === index) return;
  
  // Throttle - не чаще чем раз в BANNER_SWAP_THROTTLE мс
  const now = Date.now();
  if (now - lastBannerSwapTime < BANNER_SWAP_THROTTLE) return;
  lastBannerSwapTime = now;
  
  // Живое перестроение
  const items = [...banners.value];
  const [removed] = items.splice(sourceIndex, 1);
  items.splice(index, 0, removed);
  banners.value = items;
  draggingBannerIndex.value = index;
};

const onBannerDrop = async (event: DragEvent) => {
  event.preventDefault();
  await saveBannerOrder();
};

const onBannerDragEnd = (event: DragEvent) => {
  if (event.target instanceof HTMLElement) {
    event.target.style.opacity = '';
  }
  draggingBannerIndex.value = null;
  isDraggingBanner.value = false;
  lastBannerSwapTime = 0;
};

const saveBannerOrder = async () => {
  savingBannerOrder.value = true;
  try {
    const reorderData = banners.value.map((banner, index) => ({
      id: banner.id,
      sort_order: index,
    }));
    await api.banners.reorder(reorderData);
    showToaster('success', 'Порядок баннеров сохранён');
  } catch (err) {
    console.error('Failed to save banner order:', err);
    showToaster('error', 'Ошибка сохранения порядка');
    await loadBannersData();
  } finally {
    savingBannerOrder.value = false;
  }
};

// Новый баннер
const showNewBannerForm = ref(false);
const savingNewBanner = ref(false);
const newBanner = ref<any>({ name: '', cities: ['Все'], file_path: null, is_active: true });
const newBannerNameInput = ref<HTMLInputElement | null>(null);

// Модальное окно изображения
const bannerImageDialog = ref(false);
const bannerImageFile = ref<string | null>(null);
const editingBannerForImage = ref<any>(null);

// Редактирование названия баннера
const editingBannerId = ref<number | null>(null);
const originalBannerName = ref<string>('');
const bannerNameInputRefs = ref<Record<number, HTMLInputElement | null>>({});

// Все доступные города
const allCities = ref<string[]>(['Все']);

const bannerCities = computed(() => {
  const citiesSet = new Set<string>();
  banners.value.forEach(b => {
    if (Array.isArray(b.cities)) {
      b.cities.forEach((c: string) => {
        if (c !== 'Все') citiesSet.add(c);
      });
    }
  });
  return Array.from(citiesSet);
});

const activeBanners = computed(() => {
  const now = new Date();
  return banners.value.filter(b => {
    if (!b.is_active) return false;
    // Проверка города
    if (previewCity.value !== 'Все') {
      const cities = Array.isArray(b.cities) ? b.cities : [b.cities];
      if (!cities.includes(previewCity.value) && !cities.includes('Все')) return false;
    }
    if (b.start_date && new Date(b.start_date) > now) return false;
    if (b.expired_at && new Date(b.expired_at) < now) return false;
    return true;
  });
});

const isBannerScheduled = (banner: any) => {
  if (!banner.start_date) return false;
  return new Date(banner.start_date) > new Date();
};

const isBannerExpired = (banner: any) => {
  if (!banner.expired_at) return false;
  return new Date(banner.expired_at) < new Date();
};

const formatDate = (date: string) => {
  // Парсим только дату без timezone сдвига
  const dateOnly = date.split('T')[0];
  const [year, month, day] = dateOnly.split('-').map(Number);
  const localDate = new Date(year, month - 1, day);
  return localDate.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short' });
};

const loadBannersData = async () => {
  loadingBanners.value = true;
  try {
    const [bannersResponse, citiesResponse] = await Promise.all([
      api.banners.getAll(),
      api.cities.getAll()
    ]);
    
    console.log('[loadBannersData] bannersResponse:', bannersResponse);
    console.log('[loadBannersData] citiesResponse:', citiesResponse);
    
    // API может возвращать либо массив напрямую, либо { data: [...] }
    const allBanners = Array.isArray(bannersResponse) ? bannersResponse : (bannersResponse?.data || []);
    const allCitiesData = Array.isArray(citiesResponse) ? citiesResponse : (citiesResponse?.data || []);
    
    banners.value = allBanners.map((b: any) => ({
      ...b,
      cities: Array.isArray(b.cities) ? b.cities : (b.cities ? [b.cities] : ['Все'])
    }));
    
    const cityNames = allCitiesData.map((c: any) => c.name).filter((name: string) => name !== 'Все');
    allCities.value = ['Все', ...cityNames];
    
    console.log('[loadBannersData] banners.value:', banners.value);
    console.log('[loadBannersData] allCities.value:', allCities.value);
    
    carouselIndex.value = 0;
  } catch (err) {
    console.error('Failed to load banners:', err);
    banners.value = [];
  } finally {
    loadingBanners.value = false;
  }
};

const toggleBannerActive = async (banner: any) => {
  try {
    await api.banners.quickUpdate(banner.id, { is_active: !banner.is_active });
    banner.is_active = !banner.is_active;
    showToaster('success', banner.is_active ? 'Баннер активирован' : 'Баннер скрыт');
  } catch (err) {
    console.error('Failed to toggle banner:', err);
    showToaster('error', 'Ошибка обновления');
  }
};

const setBannerPeriod = async (banner: any, days: number) => {
  const startDate = new Date().toISOString().split('T')[0];
  const endDate = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
  
  try {
    await api.banners.quickUpdate(banner.id, { start_date: startDate, expired_at: endDate });
    banner.start_date = startDate;
    banner.expired_at = endDate;
    showToaster('success', `Период: ${days} дней`);
  } catch (err) {
    console.error('Failed to set banner period:', err);
    showToaster('error', 'Ошибка обновления');
  }
};

const updateBannerDate = async (banner: any, field: 'start_date' | 'expired_at', value: string) => {
  try {
    await api.banners.quickUpdate(banner.id, { [field]: value || null });
    banner[field] = value || null;
    showToaster('success', 'Дата обновлена');
  } catch (err) {
    console.error('Failed to update banner date:', err);
    showToaster('error', 'Ошибка обновления');
  }
};

const clearBannerPeriod = async (banner: any) => {
  try {
    await api.banners.quickUpdate(banner.id, { start_date: null, expired_at: null });
    banner.start_date = null;
    banner.expired_at = null;
    showToaster('success', 'Период сброшен');
  } catch (err) {
    console.error('Failed to clear banner period:', err);
    showToaster('error', 'Ошибка обновления');
  }
};

const deleteBanner = async (banner: any) => {
  const confirmed = await confirm({
    title: 'Удаление баннера',
    message: `Удалить баннер "${banner.name}"?`,
    confirmText: 'Удалить',
    type: 'danger',
  });
  if (!confirmed) return;
  
  try {
    await api.banners.delete(banner.id);
    banners.value = banners.value.filter(b => b.id !== banner.id);
    showToaster('success', 'Баннер удалён');
  } catch (err) {
    console.error('Failed to delete banner:', err);
    showToaster('error', 'Ошибка удаления');
  }
};

// Inline сохранение поля баннера
const saveBannerField = async (banner: any, field: string) => {
  try {
    await api.banners.quickUpdate(banner.id, { [field]: banner[field] });
  } catch (err) {
    console.error('Failed to save banner field:', err);
    showToaster('error', 'Ошибка сохранения');
  }
};

// Редактирование названия баннера
const setBannerNameInputRef = (el: any, id: number) => {
  if (el) bannerNameInputRefs.value[id] = el;
};

const startEditingBannerName = (banner: any) => {
  editingBannerId.value = banner.id;
  originalBannerName.value = banner.name;
  nextTick(() => {
    bannerNameInputRefs.value[banner.id]?.focus();
    bannerNameInputRefs.value[banner.id]?.select();
  });
};

const finishEditingBannerName = async (banner: any) => {
  if (banner.name !== originalBannerName.value) {
    await saveBannerField(banner, 'name');
  }
  editingBannerId.value = null;
};

const cancelEditingBannerName = (banner: any) => {
  banner.name = originalBannerName.value;
  editingBannerId.value = null;
};

// Переключение городов для существующего баннера
const toggleBannerCity = async (banner: any, city: string) => {
  if (!banner.cities) banner.cities = [];
  
  if (city === 'Все') {
    // Если выбрано "Все", очищаем остальные и ставим только "Все"
    banner.cities = ['Все'];
  } else {
    // Если выбран конкретный город
    const idx = banner.cities.indexOf(city);
    
    // Убираем "Все" если он был
    const allIdx = banner.cities.indexOf('Все');
    if (allIdx !== -1) {
      banner.cities.splice(allIdx, 1);
    }
    
    if (idx === -1) {
      // Добавляем город
      banner.cities.push(city);
    } else {
      // Убираем город
      banner.cities.splice(idx, 1);
    }
    
    // Если ничего не выбрано, ставим "Все"
    if (banner.cities.length === 0) {
      banner.cities = ['Все'];
    }
  }
  
  await saveBannerField(banner, 'cities');
};

// Переключение городов для нового баннера
const toggleNewBannerCity = (city: string) => {
  if (!newBanner.value.cities) newBanner.value.cities = [];
  
  if (city === 'Все') {
    newBanner.value.cities = ['Все'];
  } else {
    const idx = newBanner.value.cities.indexOf(city);
    
    // Убираем "Все"
    const allIdx = newBanner.value.cities.indexOf('Все');
    if (allIdx !== -1) {
      newBanner.value.cities.splice(allIdx, 1);
    }
    
    if (idx === -1) {
      newBanner.value.cities.push(city);
    } else {
      newBanner.value.cities.splice(idx, 1);
    }
    
    if (newBanner.value.cities.length === 0) {
      newBanner.value.cities = ['Все'];
    }
  }
};

// Новый баннер
// Скролл к форме добавления нового баннера
const newBannerFormRef = ref<HTMLElement | null>(null);

const scrollToNewBanner = () => {
  startNewBanner();
  // Даём время на рендер формы, затем плавный скролл
  setTimeout(() => {
    newBannerFormRef.value?.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }, 100);
};

const startNewBanner = () => {
  showNewBannerForm.value = true;
  newBanner.value = { name: '', cities: ['Все'], file_path: null, is_active: true };
  nextTick(() => {
    newBannerNameInput.value?.focus();
  });
};

const cancelNewBanner = () => {
  showNewBannerForm.value = false;
  newBanner.value = { name: '', cities: ['Все'], file_path: null, is_active: true };
};

const saveNewBanner = async () => {
  if (!newBanner.value.name || !newBanner.value.file_path) return;
  
  savingNewBanner.value = true;
  try {
    const response = await api.banners.add({
      name: newBanner.value.name,
      cities: newBanner.value.cities,
      file_path: newBanner.value.file_path,
      is_active: true,
    } as any);
    
    if (response?.data) {
      banners.value.push(response.data);
    }
    showToaster('success', 'Баннер создан');
    cancelNewBanner();
  } catch (err) {
    console.error('Failed to create banner:', err);
    showToaster('error', 'Ошибка создания');
  } finally {
    savingNewBanner.value = false;
  }
};

// Модальное окно изображения
const openBannerImageDialog = (banner: any) => {
  editingBannerForImage.value = banner;
  bannerImageFile.value = null;
  bannerImageDialog.value = true;
};

const closeBannerImageDialog = () => {
  bannerImageDialog.value = false;
  editingBannerForImage.value = null;
  bannerImageFile.value = null;
};

const onBannerImageUpload = (url: string) => {
  bannerImageFile.value = url;
};

const onBannerUploadError = (message: string) => {
  console.error('[Banner Upload Error]', message);
  // Ошибка уже показана через showToaster в компоненте VideoFileInput
};

const applyBannerImage = async () => {
  if (!bannerImageFile.value || !editingBannerForImage.value) return;
  
  const banner = editingBannerForImage.value;
  
  // Если это новый баннер (без id)
  if (!banner.id) {
    banner.file_path = bannerImageFile.value;
    closeBannerImageDialog();
    return;
  }
  
  // Существующий баннер - обновляем через API
  try {
    await api.banners.quickUpdate(banner.id, { file_path: bannerImageFile.value });
    banner.file_path = bannerImageFile.value;
    showToaster('success', 'Изображение обновлено');
    closeBannerImageDialog();
  } catch (err) {
    console.error('Failed to update banner image:', err);
    showToaster('error', 'Ошибка загрузки');
  }
};

const pasteFromClipboard = async () => {
  try {
    const items = await navigator.clipboard.read();
    for (const item of items) {
      for (const type of item.types) {
        if (type.startsWith('image/')) {
          const blob = await item.getType(type);
          const reader = new FileReader();
          reader.onload = (e) => {
            bannerImageFile.value = e.target?.result as string;
          };
          reader.readAsDataURL(blob);
          return;
        }
      }
    }
    showToaster('error', 'В буфере нет изображения');
  } catch (err) {
    showToaster('error', 'Не удалось прочитать буфер обмена');
  }
};

// Автопрокрутка карусели
let carouselInterval: ReturnType<typeof setInterval> | null = null;
const startCarouselAutoplay = () => {
  if (carouselInterval) clearInterval(carouselInterval);
  carouselInterval = setInterval(() => {
    if (activeBanners.value.length > 1) {
      carouselIndex.value = (carouselIndex.value + 1) % activeBanners.value.length;
    }
  }, 4000);
};

watch(activeBanners, () => {
  carouselIndex.value = 0;
  startCarouselAutoplay();
}, { immediate: true });

onUnmounted(() => {
  if (carouselInterval) clearInterval(carouselInterval);
});

const loadStoriesData = async () => {
  loadingGroups.value = true;
  try {
    const actualsResponse = await api.actuals.getAll();
    const storiesResponse = await api.histories.getAll();
    
    // API может возвращать либо массив напрямую, либо { data: [...] }
    const allActuals = Array.isArray(actualsResponse) ? actualsResponse : (actualsResponse?.data || []);
    const allStories = Array.isArray(storiesResponse) ? storiesResponse : (storiesResponse?.data || []);
    
    console.log('[loadStoriesData] actualsResponse:', actualsResponse);
    console.log('[loadStoriesData] storiesResponse:', storiesResponse);
    console.log('[loadStoriesData] allActuals:', allActuals);
    console.log('[loadStoriesData] allStories:', allStories);
    
    const storiesByGroup: Record<string, any[]> = {};
    allStories.forEach((story: any) => {
      const groupName = story.actual_group || 'Без группы';
      if (!storiesByGroup[groupName]) {
        storiesByGroup[groupName] = [];
      }
      storiesByGroup[groupName].push(story);
    });
    
    console.log('[loadStoriesData] storiesByGroup:', storiesByGroup);
    
    // Теперь actualsResponse уже содержит все группы из БД (включая системные)
    groups.value = allActuals.map((actual: any) => ({
      ...actual,
      cover: actual.image || storiesByGroup[actual.name]?.[0]?.cover_path || null,
      stories: storiesByGroup[actual.name] || [],
      is_system: actual.is_system || false,
    }));
    
    console.log('[loadStoriesData] groups.value:', groups.value);
    
    const citiesResponse = await api.cities.getAll();
    const citiesData = Array.isArray(citiesResponse) ? citiesResponse : (citiesResponse?.data || []);
    cities.value = [{ name: 'Все' }, ...citiesData];
    
    // Автоматически выбираем первую группу если нет выбранной группы
    if (!selectedGroup.value && groups.value.length > 0) {
      selectGroup(groups.value[0]);
    }
    
    // Обновляем выбранную группу
    if (selectedGroup.value && !isNewGroup.value) {
      const updated = groups.value.find(g => g.name === selectedGroup.value.name);
      if (updated) selectedGroup.value = { ...updated };
    }
  } catch (err) {
    console.error('Failed to load stories data:', err);
  } finally {
    loadingGroups.value = false;
  }
};

const selectGroup = (group: any) => {
  selectedGroup.value = { ...group };
  isNewGroup.value = false;
  selectedStoryIds.value = []; // Сбрасываем выбор при смене группы
};

const createNewGroup = () => {
  selectedGroup.value = { name: '', cover: null, stories: [], is_welcome: false };
  isNewGroup.value = true;
};

// Inline создание группы
const startInlineCreate = () => {
  showInlineCreate.value = true;
  inlineNewGroup.value = { name: '', cover: null };
  nextTick(() => {
    inlineNameInput.value?.focus();
  });
};

const cancelInlineCreate = () => {
  showInlineCreate.value = false;
  inlineNewGroup.value = { name: '', cover: null };
};

const triggerInlineCoverUpload = () => inlineCoverInput.value?.click();

const onInlineCoverChange = async (e: Event) => {
  const file = (e.target as HTMLInputElement).files?.[0];
  if (!file) return;
  
  // Открываем диалог кропа для обложки группы (1:1) в режиме inline
  isInlineCoverCrop.value = true;
  const reader = new FileReader();
  reader.onload = (ev) => {
    coverCropImageUrl.value = ev.target?.result as string;
    coverCropDialog.value = true;
  };
  reader.readAsDataURL(file);
};

const saveInlineGroup = async () => {
  if (!inlineNewGroup.value.name?.trim()) {
    showToaster('error', 'Введите название группы');
    inlineNameInput.value?.focus();
    return;
  }
  
  savingInlineGroup.value = true;
  try {
    const updatedGroups = [
      ...groups.value.map(g => ({
        name: g.name,
        image: g.cover || g.image,
        is_welcome: g.is_welcome
      })),
      { name: inlineNewGroup.value.name.trim(), image: inlineNewGroup.value.cover, is_welcome: false }
    ];
    
    await api.actuals.add(updatedGroups);
    showToaster('success', 'Группа создана');
    
    cancelInlineCreate();
    await loadStoriesData();
    
    // Выбираем новую группу
    const newGroup = groups.value.find(g => g.name === inlineNewGroup.value.name.trim());
    if (newGroup) selectGroup(newGroup);
  } catch (err) {
    console.error('Failed to create group:', err);
    showToaster('error', 'Ошибка создания группы');
  } finally {
    savingInlineGroup.value = false;
  }
};

// Обработка переключения "Приветственная группа"
const onWelcomeToggle = async (value: boolean) => {
  if (value) {
    // Выключаем is_welcome у всех других групп локально
    groups.value.forEach(g => {
      if (g.name !== selectedGroup.value?.name) {
        g.is_welcome = false;
      }
    });
  }
  
  // Автоматически сохраняем изменение is_welcome
  if (!isNewGroup.value && selectedGroup.value?.name) {
    try {
      const updatedGroups = groups.value.map(g => ({
        name: g.name,
        image: g.cover || g.image,
        is_welcome: g.name === selectedGroup.value.name ? value : (value ? false : g.is_welcome)
      }));
      
      await api.actuals.add(updatedGroups);
      showToaster('success', value ? 'Приветственная группа установлена' : 'Приветственная группа снята');
      await loadStoriesData();
      
      // Восстанавливаем выбранную группу
      const updatedGroup = groups.value.find(g => g.name === selectedGroup.value?.name);
      if (updatedGroup) selectedGroup.value = { ...updatedGroup };
    } catch (err) {
      console.error('Failed to update welcome group:', err);
      showToaster('error', 'Ошибка сохранения');
      // Откатываем локальное изменение
      await loadStoriesData();
    }
  }
};

const saveGroup = async () => {
  if (!selectedGroup.value?.name?.trim()) {
    showToaster('error', 'Введите название группы');
    return;
  }
  
  savingGroup.value = true;
  try {
    // Собираем обновлённые группы с учётом is_welcome
    const updatedGroups = groups.value
      .filter(g => g.name !== selectedGroup.value.name)
      .map(g => ({
        name: g.name,
        image: g.cover || g.image,
        is_welcome: selectedGroup.value.is_welcome ? false : g.is_welcome // Если текущая группа welcome, остальные = false
      }));
    
    // Добавляем текущую редактируемую группу
    updatedGroups.push({
      name: selectedGroup.value.name,
      image: selectedGroup.value.cover,
      is_welcome: selectedGroup.value.is_welcome || false
    });
    
    await api.actuals.add(updatedGroups);
    showToaster('success', isNewGroup.value ? 'Группа создана' : 'Сохранено');
    
    await loadStoriesData();
    const updatedGroup = groups.value.find(g => g.name === selectedGroup.value.name);
    if (updatedGroup) selectGroup(updatedGroup);
  } catch (err) {
    console.error('Failed to save group:', err);
    showToaster('error', 'Ошибка сохранения');
  } finally {
    savingGroup.value = false;
  }
};

const deleteGroup = async () => {
  if (isSystemGroup.value) return;
  const confirmed = await confirm({
    title: 'Удаление группы',
    message: `Удалить группу "${selectedGroup.value.name}"? Все истории в группе будут удалены.`,
    confirmText: 'Удалить',
    type: 'danger',
  });
  if (!confirmed) return;
  
  try {
    for (const story of selectedGroup.value.stories || []) {
      await api.histories.delete(story.id);
    }
    
    const updatedGroups = groups.value
      .filter(g => g.name !== selectedGroup.value.name)
      .map(g => ({ name: g.name, image: g.cover }));
    
    await api.actuals.add(updatedGroups);
    showToaster('success', 'Группа удалена');
    selectedGroup.value = null;
    await loadStoriesData();
  } catch (err) {
    console.error('Failed to delete group:', err);
    showToaster('error', 'Ошибка удаления');
  }
};

const triggerCoverUpload = () => coverInput.value?.click();

const onCoverChange = async (event: Event) => {
  const file = (event.target as HTMLInputElement).files?.[0];
  if (!file) return;
  
  // Открываем диалог кропа для обложки группы (1:1) в обычном режиме
  isInlineCoverCrop.value = false;
  const reader = new FileReader();
  reader.onload = (e) => {
    coverCropImageUrl.value = e.target?.result as string;
    coverCropDialog.value = true;
  };
  reader.readAsDataURL(file);
};

// Инициализация кропера для обложки после открытия диалога
watch(coverCropImageUrl, async (newValue) => {
  if (newValue && coverCropDialog.value) {
    await nextTick();
    const imageElement = coverCropImageEl.value;
    if (imageElement) {
      if (coverCropper.value) {
        coverCropper.value.destroy();
      }
      coverCropper.value = new Cropper(imageElement, {
        aspectRatio: 1, // 1:1 квадрат для обложки группы
        autoCropArea: 1,
        responsive: true,
        viewMode: 1,
      });
    }
  }
});

const applyCoverCrop = async () => {
  if (coverCropper.value) {
    const canvas = coverCropper.value.getCroppedCanvas();
    const croppedDataUrl = canvas.toDataURL();
    
    if (isInlineCoverCrop.value) {
      // Для inline создания группы - загружаем на сервер
      try {
        const blob = await new Promise<Blob>((resolve) => {
          canvas.toBlob((b) => resolve(b!), 'image/jpeg', 0.9);
        });
        const file = new File([blob], 'cover.jpg', { type: 'image/jpeg' });
        const formData = new FormData();
        formData.append('files', file);
        const response = await api.upload.post(formData);
        if (response?.data?.[0]) {
          inlineNewGroup.value.cover = response.data[0];
        }
      } catch (err) {
        console.error('Failed to upload cover:', err);
        showToaster('error', 'Ошибка загрузки обложки');
      }
    } else {
      // Для редактирования существующей группы - устанавливаем base64
      selectedGroup.value.cover = croppedDataUrl;
    }
    
    closeCoverCropDialog();
  }
};

const closeCoverCropDialog = () => {
  coverCropDialog.value = false;
  if (coverCropper.value) {
    coverCropper.value.destroy();
    coverCropper.value = null;
  }
  coverCropImageUrl.value = null;
  isInlineCoverCrop.value = false;
  // Сброс input для повторной загрузки того же файла
  if (coverInput.value) coverInput.value.value = '';
  if (inlineCoverInput.value) inlineCoverInput.value.value = '';
};

const addStory = () => {
  editingStory.value = {
    type: 'image',
    name: '',
    cities: ['Все'],
    is_active: true,
    file_path: null,
    actual_group: selectedGroup.value.name
  };
  storyDialog.value = true;
};

const editStory = (story: any) => {
  // Совместимость: если есть city, конвертируем в cities
  const cities = story.cities || (story.city ? [story.city] : ['Все']);
  editingStory.value = { ...story, cities };
  storyDialog.value = true;
};

const deleteStory = async (story: any) => {
  const confirmed = await confirm({
    title: 'Удаление истории',
    message: 'Удалить эту историю?',
    confirmText: 'Удалить',
    type: 'danger',
  });
  if (!confirmed) return;
  
  try {
    await api.histories.delete(story.id);
    showToaster('success', 'История удалена');
    await loadStoriesData();
  } catch (err) {
    console.error('Failed to delete story:', err);
    showToaster('error', 'Ошибка удаления');
  }
};

// Выбор историй для массового удаления
const toggleStorySelection = (storyId: number) => {
  const idx = selectedStoryIds.value.indexOf(storyId);
  if (idx === -1) {
    selectedStoryIds.value.push(storyId);
  } else {
    selectedStoryIds.value.splice(idx, 1);
  }
};

// Переключение активности истории
const toggleStoryActive = async (story: any) => {
  try {
    const newStatus = !story.is_active;
    await api.histories.update(story.id, {
      ...story,
      is_active: newStatus ? 1 : 0,
    });
    story.is_active = newStatus;
    showToaster('success', newStatus ? 'История активирована' : 'История скрыта');
  } catch (err) {
    console.error('Failed to toggle story:', err);
    showToaster('error', 'Ошибка обновления');
  }
};

// Массовое удаление выбранных историй
const deleteSelectedStories = async () => {
  if (!selectedStoryIds.value.length) return;
  
  const confirmed = await confirm({
    title: 'Удаление историй',
    message: `Удалить ${selectedStoryIds.value.length} ${selectedStoryIds.value.length === 1 ? 'историю' : selectedStoryIds.value.length < 5 ? 'истории' : 'историй'}?`,
    confirmText: 'Удалить',
    type: 'danger',
  });
  if (!confirmed) return;
  
  deletingStories.value = true;
  try {
    await api.histories.deleteMany(selectedStoryIds.value);
    showToaster('success', 'Истории удалены');
    selectedStoryIds.value = [];
    await loadStoriesData();
  } catch (err) {
    console.error('Failed to delete stories:', err);
    showToaster('error', 'Ошибка удаления');
  } finally {
    deletingStories.value = false;
  }
};

// Клик по карточке - открывает модальное окно редактирования
const onStoryCardClick = (story: any, event: MouseEvent) => {
  // Не открываем модал если клик по checkbox, toggle или кнопке удаления
  const target = event.target as HTMLElement;
  if (target.closest('.stories-manager__story-checkbox') || 
      target.closest('.stories-manager__story-toggle') ||
      target.closest('.stories-manager__story-btn')) {
    return;
  }
  editStory(story);
};

const closeStoryDialog = () => {
  storyDialog.value = false;
  editingStory.value = { type: 'image', name: '', cities: ['Все'], is_active: true, file_path: null };
};

// Города для историй
const storyCities = computed(() => {
  const cityNames = cities.value.map((c: any) => c.name).filter((name: string) => name !== 'Все');
  return ['Все', ...cityNames];
});

const toggleStoryCity = (city: string) => {
  if (!editingStory.value.cities) editingStory.value.cities = [];
  
  if (city === 'Все') {
    editingStory.value.cities = ['Все'];
  } else {
    const idx = editingStory.value.cities.indexOf(city);
    const allIdx = editingStory.value.cities.indexOf('Все');
    
    if (allIdx !== -1) {
      editingStory.value.cities.splice(allIdx, 1);
    }
    
    if (idx === -1) {
      editingStory.value.cities.push(city);
    } else {
      editingStory.value.cities.splice(idx, 1);
    }
    
    if (editingStory.value.cities.length === 0) {
      editingStory.value.cities = ['Все'];
    }
  }
};

const triggerMediaUpload = () => mediaInput.value?.click();

const onMediaChange = async (event: Event) => {
  const file = (event.target as HTMLInputElement).files?.[0];
  if (!file) return;
  
  const reader = new FileReader();
  reader.onload = (e) => {
    const result = e.target?.result as string;
    
    // Если это изображение - открываем диалог кропа с соотношением 9:16
    if (file.type.startsWith('image/')) {
      mediaCropImageUrl.value = result;
      mediaCropDialog.value = true;
    } else {
      // Для видео - устанавливаем напрямую без кропа
      editingStory.value.file_path = result;
    }
  };
  reader.readAsDataURL(file);
};

// Инициализация кропера для медиа истории после открытия диалога
watch(mediaCropImageUrl, async (newValue) => {
  if (newValue && mediaCropDialog.value) {
    await nextTick();
    const imageElement = mediaCropImageEl.value;
    if (imageElement) {
      if (mediaCropper.value) {
        mediaCropper.value.destroy();
      }
      mediaCropper.value = new Cropper(imageElement, {
        aspectRatio: 9 / 16, // 9:16 вертикальный для историй
        autoCropArea: 1,
        responsive: true,
        viewMode: 1,
      });
    }
  }
});

const applyMediaCrop = () => {
  if (mediaCropper.value) {
    const canvas = mediaCropper.value.getCroppedCanvas();
    editingStory.value.file_path = canvas.toDataURL();
    closeMediaCropDialog();
  }
};

const closeMediaCropDialog = () => {
  mediaCropDialog.value = false;
  if (mediaCropper.value) {
    mediaCropper.value.destroy();
    mediaCropper.value = null;
  }
  mediaCropImageUrl.value = null;
  // Сброс input для повторной загрузки того же файла
  if (mediaInput.value) mediaInput.value.value = '';
};

const saveStory = async () => {
  if (!editingStory.value.file_path) {
    showToaster('error', 'Загрузите медиафайл');
    return;
  }
  
  savingStory.value = true;
  try {
    if (editingStory.value.id) {
      // Update - бэкенд ожидает 'file' и 'name' обязательно
      const updatePayload = {
        name: editingStory.value.name || 'История',
        cities: editingStory.value.cities || ['Все'],
        actual_group: selectedGroup.value.name,
        type: editingStory.value.type,
        is_active: editingStory.value.is_active ? 1 : 0,
        file: editingStory.value.file_path
      };
      await api.histories.update(editingStory.value.id, updatePayload);
      showToaster('success', 'История обновлена');
    } else {
      // Create - бэкенд ожидает 'file_path'
      const createPayload = {
        name: editingStory.value.name || '',
        cities: editingStory.value.cities || ['Все'],
        actual_group: selectedGroup.value.name,
        type: editingStory.value.type,
        is_active: editingStory.value.is_active ? 1 : 0,
        file_path: editingStory.value.file_path
      };
      await api.histories.add(createPayload);
      showToaster('success', 'История добавлена');
    }
    
    closeStoryDialog();
    await loadStoriesData();
  } catch (err) {
    console.error('Failed to save story:', err);
    showToaster('error', 'Ошибка сохранения');
  } finally {
    savingStory.value = false;
  }
};

// ============== ОСНОВНОЙ СПИСОК ==============
const getList = async () => {
  console.log('[getList] contentTab:', layoutStore.contentTab);
  
  if (layoutStore.contentTab === 'histories') {
    console.log('[getList] Loading stories data...');
    await loadStoriesData();
    return;
  }
  
  if (layoutStore.contentTab === 'banners') {
    console.log('[getList] Loading banners data...');
    await loadBannersData();
    return;
  }
  
  if (layoutStore.contentTab === 'shops') {
    console.log('[getList] Loading shops data...');
    await loadShopsData();
    return;
  }
  
  if (layoutStore.contentTab === 'news') {
    console.log('[getList] Loading news data...');
    await loadNewsData();
    return;
  }
  
  // Все известные вкладки обработаны выше с early return
  // Этот код недостижим при текущем перечне ContentItems
};

const onDelete = async (id: number) => {
  try {
    const response = await api[layoutStore.contentTab].delete(id);
    if (response.message) showToaster('success', String(response.message));
    await getList();
  } catch (err) {
    console.log(err);
  }
};

useHead({
  title: () => (layoutStore.contentTab ? `${t('admin.nav.content')} - ${t(`admin.content.${layoutStore.contentTab}`)}` : t('admin.nav.content')),
});

onMounted(async () => {
  console.log('[onMounted] Starting...');
  const tab = String(route.query.tab) as AdminEnums.ContentItems;
  console.log('[onMounted] route.query.tab:', tab);
  if (tab && tab in AdminEnums.ContentItems) {
    if (tab !== layoutStore.contentTab) {
      layoutStore.contentTab = tab;
      await router.replace({ query: { tab: tab } });
    }
  } else {
    await router.replace({ query: { tab: layoutStore.contentTab } });
  }
  console.log('[onMounted] Calling getList with tab:', layoutStore.contentTab);
  await getList();
  console.log('[onMounted] Finished getList');
});

watch(
  () => layoutStore.contentTab,
  async (tab) => {
    if (tab && tab in AdminEnums.ContentItems) {
      router.replace({ query: { tab: tab } });
      await getList();
    }
  },
);
</script>

<style scoped>
.content-page {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

@media (min-width: 960px) {
  .content-page {
    gap: 1.5rem;
  }
}

.content-page__header {
  display: flex;
  flex-direction: column;
  align-items: stretch;
  gap: 0.75rem;
}

@media (min-width: 600px) {
  .content-page__header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
  }
}

.content-page__actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  width: 100%;
}

@media (min-width: 600px) {
  .content-page__actions {
    width: auto;
  }
}

.content-page__add-btn {
  flex: 1;
}

@media (min-width: 600px) {
  .content-page__add-btn {
    flex: none;
  }
}

.content-page__content {
  transition: opacity 0.2s ease;
}

.content-page__content--loading {
  opacity: 0.6;
  pointer-events: none;
}

.content-fade-enter-active,
.content-fade-leave-active {
  transition: opacity 0.25s ease, transform 0.25s ease;
}

.content-fade-enter-from {
  opacity: 0;
  transform: translateY(10px);
}

.content-fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

/* Категории */
.content-page__categories-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0 1rem;
  height: 40px;
  font-weight: 600;
  border-color: var(--color-accent) !important;
  color: var(--color-accent) !important;
}

.content-page__categories-btn:hover {
  background-color: rgba(152, 179, 93, 0.1) !important;
}

.content-page__categories-icon {
  font-size: 1.125rem;
}

.categories-modal {
  background-color: var(--color-bg-card) !important;
}

.categories-modal__title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 1.25rem;
  font-weight: 600;
  padding: 1.25rem 1.5rem;
  color: var(--color-text-primary);
}

.categories-modal__title .iconify {
  font-size: 1.5rem;
  color: var(--color-accent);
}

.categories-modal__content {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
  padding: 0 1.5rem 1rem;
}

.categories-modal__add-form {
  display: flex;
  gap: 0.75rem;
  align-items: center;
}

.categories-modal__input {
  flex: 1;
}

.categories-modal__list-container {
  min-height: 150px;
  max-height: 300px;
  overflow-y: auto;
  border: 1px solid var(--color-border);
  border-radius: 12px;
  background: var(--color-bg-secondary);
}

.categories-modal__loading,
.categories-modal__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  height: 150px;
  color: var(--color-text-secondary);
}

.categories-modal__empty .iconify {
  font-size: 2.5rem;
  opacity: 0.5;
}

.categories-modal__list {
  display: flex;
  flex-direction: column;
}

.categories-modal__list--dragging .categories-modal__item:not(.categories-modal__item--dragging) {
  transition: transform 0.2s cubic-bezier(0.2, 0, 0, 1);
}

.categories-modal__item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  border-bottom: 1px solid var(--color-border);
  cursor: grab;
  transition: transform 0.2s cubic-bezier(0.2, 0, 0, 1), 
              background 0.15s ease, 
              opacity 0.2s ease,
              box-shadow 0.2s ease;
}

.categories-modal__item:active {
  cursor: grabbing;
}

.categories-modal__item:last-child {
  border-bottom: none;
}

.categories-modal__item:hover {
  background-color: var(--color-bg-hover);
}

.categories-modal__item--dragging {
  opacity: 0.5;
  transform: scale(0.98);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  background: var(--color-bg-tertiary);
  z-index: 10;
  position: relative;
}

.categories-modal__item-drag {
  display: flex;
  align-items: center;
  color: var(--color-text-muted);
  opacity: 0.3;
  transition: opacity 0.15s ease, color 0.15s ease;
}

.categories-modal__item:hover .categories-modal__item-drag {
  opacity: 1;
  color: var(--color-accent);
}

.categories-modal__item--editing .categories-modal__item-drag {
  opacity: 0.2;
  pointer-events: none;
}

.categories-modal__item-name {
  flex: 1;
  font-size: 0.9rem;
  font-weight: 500;
  color: var(--color-text-primary);
}

.categories-modal__item-edit-input {
  flex: 1;
  font-size: 0.9rem;
  font-weight: 500;
  color: var(--color-text-primary);
  background: var(--color-bg-secondary);
  border: 1px solid var(--color-accent);
  border-radius: 6px;
  padding: 0.375rem 0.625rem;
  outline: none;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.categories-modal__item-edit-input:focus {
  border-color: var(--color-accent);
  box-shadow: 0 0 0 2px rgba(var(--color-accent-rgb), 0.2);
}

.categories-modal__item-actions {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  opacity: 0;
  transition: opacity 0.15s ease;
}

.categories-modal__item:hover .categories-modal__item-actions,
.categories-modal__item--editing .categories-modal__item-actions {
  opacity: 1;
}

.categories-modal__item-actions .v-btn {
  width: 32px !important;
  height: 32px !important;
}

.categories-modal__actions {
  padding: 0.75rem 1.5rem 1.25rem;
  justify-content: flex-end;
}

/* ============== STORIES MANAGER ============== */
.stories-manager {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.stories-manager__content {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

@media (min-width: 960px) {
  .stories-manager__content {
    flex-direction: row;
    gap: 1.5rem;
  }
}

/* Sidebar */
.stories-manager__sidebar {
  background: var(--color-bg-card);
  border-radius: 1rem;
  overflow: hidden;
  box-shadow: 0 2px 8px var(--color-shadow);
}

@media (min-width: 960px) {
  .stories-manager__sidebar {
    width: 280px;
    flex-shrink: 0;
    max-height: calc(100vh - 220px);
    overflow-y: auto;
  }
}

.stories-manager__sidebar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.875rem 1rem;
  border-bottom: 1px solid var(--color-border);
  background: var(--color-bg-secondary);
}

.stories-manager__sidebar-title {
  font-weight: 600;
  font-size: 0.9rem;
  color: var(--color-text-primary);
}

.stories-manager__groups-list {
  padding: 0.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.stories-manager__loading,
.stories-manager__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 2rem 1rem;
  color: var(--color-text-secondary);
}

.stories-manager__empty .iconify {
  font-size: 2.5rem;
  opacity: 0.4;
}

/* Group item */
.stories-manager__group-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.625rem 0.75rem;
  border-radius: 0.625rem;
  cursor: pointer;
  transition: all 0.15s ease;
}

.stories-manager__group-item:hover {
  background: var(--color-bg-hover);
}

.stories-manager__group-item--active {
  background: var(--color-accent-light);
  box-shadow: inset 0 0 0 2px var(--color-accent);
}

/* Drag & Drop стили для групп - плавное перестроение */
.stories-manager__group-item {
  transition: transform 0.2s cubic-bezier(0.2, 0, 0, 1), 
              box-shadow 0.2s ease,
              background 0.15s ease;
}

.stories-manager__group-item--dragging {
  opacity: 0.6;
  transform: scale(0.95);
  background: var(--color-bg-tertiary);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
  z-index: 100;
  position: relative;
}

.stories-manager__group-drag-handle {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  margin-left: -4px;
  color: var(--color-text-muted);
  opacity: 0.3;
  cursor: grab;
  transition: opacity 0.15s ease, color 0.15s ease;
}

.stories-manager__group-item:hover .stories-manager__group-drag-handle {
  opacity: 1;
  color: var(--color-accent);
}

.stories-manager__group-drag-handle:active {
  cursor: grabbing;
}

.stories-manager__group-cover {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  overflow: visible;
  background: var(--color-bg-secondary);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  border: 2px solid var(--color-accent);
  position: relative;
}

.stories-manager__group-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 50%;
}

.stories-manager__group-cover .iconify {
  font-size: 1.25rem;
  color: var(--color-text-muted);
}

.stories-manager__group-welcome-badge {
  position: absolute;
  bottom: -4px;
  right: -4px;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: linear-gradient(135deg, #FFA000, #FF6D00);
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid var(--color-bg-card);
}

.stories-manager__group-welcome-badge .iconify {
  font-size: 0.625rem;
  color: white;
}

.stories-manager__group-item--welcome {
  background: linear-gradient(135deg, rgba(255, 193, 7, 0.08), rgba(255, 152, 0, 0.04));
  border-color: rgba(255, 193, 7, 0.3);
}

.stories-manager__group-item--welcome .stories-manager__group-cover {
  border-color: #FFA000;
}

/* Inline создание группы */
.stories-manager__inline-create {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.625rem;
  background: var(--color-bg-secondary);
  border: 2px dashed var(--color-accent);
  border-radius: 0.5rem;
  animation: slideIn 0.2s ease;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(-8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.stories-manager__inline-cover {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: var(--color-bg-card);
  border: 2px dashed var(--color-border);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  cursor: pointer;
  transition: all 0.15s ease;
  overflow: hidden;
}

.stories-manager__inline-cover:hover {
  border-color: var(--color-accent);
  background: var(--color-bg-hover);
}

.stories-manager__inline-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.stories-manager__inline-cover .iconify {
  font-size: 1.125rem;
  color: var(--color-text-muted);
}

.stories-manager__inline-form {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  min-width: 0;
}

.stories-manager__inline-input {
  flex: 1;
  min-width: 0;
  padding: 0.375rem 0.625rem;
  border: 1px solid var(--color-border);
  border-radius: 0.375rem;
  background: var(--color-bg-card);
  color: var(--color-text-primary);
  font-size: 0.8125rem;
  outline: none;
  transition: border-color 0.15s ease;
}

.stories-manager__inline-input::placeholder {
  color: var(--color-text-muted);
}

.stories-manager__inline-input:focus {
  border-color: var(--color-accent);
}

.stories-manager__inline-actions {
  display: flex;
  gap: 0.125rem;
  flex-shrink: 0;
}

.stories-manager__group-info {
  display: flex;
  flex-direction: column;
  gap: 0.125rem;
  min-width: 0;
}

.stories-manager__group-name {
  font-weight: 600;
  font-size: 0.875rem;
  color: var(--color-text-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.stories-manager__group-count {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}

/* Main panel */
.stories-manager__main {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 1rem;
  min-width: 0;
}

.stories-manager__no-selection {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 3rem 2rem;
  background: var(--color-bg-card);
  border-radius: 1rem;
  color: var(--color-text-secondary);
}

.stories-manager__no-selection .iconify {
  font-size: 3rem;
  opacity: 0.3;
}

/* Group edit */
.stories-manager__group-edit-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.stories-manager__section-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text-primary);
  margin: 0;
}

.stories-manager__section-title .iconify {
  color: var(--color-accent);
}

.stories-manager__group-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.stories-manager__group-form {
  display: flex;
  align-items: center;
  gap: 1rem;
}

/* Cover */
.stories-manager__cover-preview {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  overflow: hidden;
  background: var(--color-bg-secondary);
  border: 3px solid var(--color-accent);
  cursor: pointer;
  position: relative;
  flex-shrink: 0;
  transition: transform 0.15s ease;
}

.stories-manager__cover-preview:hover {
  transform: scale(1.05);
}

.stories-manager__cover-preview img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.stories-manager__cover-preview--empty {
  border-style: dashed;
}

.stories-manager__cover-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: var(--color-text-muted);
}

.stories-manager__cover-placeholder .iconify {
  font-size: 1.75rem;
}

.stories-manager__cover-overlay {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.15s ease;
}

.stories-manager__cover-preview:hover .stories-manager__cover-overlay {
  opacity: 1;
}

.stories-manager__cover-overlay .iconify {
  font-size: 1.25rem;
  color: white;
}

.stories-manager__name-section {
  flex: 1;
}

/* Welcome section */
.stories-manager__welcome-section {
  grid-column: 1 / -1;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 0.25rem;
}

.stories-manager__welcome-info {
  display: flex;
  flex-direction: column;
  gap: 0.0625rem;
}

.stories-manager__welcome-label {
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--color-text-primary);
}

.stories-manager__welcome-hint {
  font-size: 0.6875rem;
  color: var(--color-text-muted);
}

/* Stories section */
.stories-manager__stories-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}

.stories-manager__stories-header-actions {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.stories-manager__delete-btn {
  font-weight: 600;
  text-transform: none;
  letter-spacing: 0;
}

.stories-manager__stories-title {
  font-weight: 600;
  color: var(--color-text-primary);
}

.stories-manager__stories-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  padding: 2rem;
  color: var(--color-text-secondary);
}

.stories-manager__stories-empty .iconify {
  font-size: 2.5rem;
  opacity: 0.4;
}

/* Stories grid */
.stories-manager__stories-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 0.75rem;
}

@media (min-width: 600px) {
  .stories-manager__stories-grid {
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  }
}

.stories-manager__story-card {
  background: var(--color-bg-secondary);
  border-radius: 0.625rem;
  overflow: hidden;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}

/* Drag & Drop стили для историй - плавное перестроение */
.stories-manager__stories-grid {
  transition: gap 0.2s ease;
}

.stories-manager__story-card {
  transition: transform 0.25s cubic-bezier(0.2, 0, 0, 1), 
              box-shadow 0.2s ease,
              opacity 0.2s ease;
  will-change: transform;
}

.stories-manager__story-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 20px var(--color-shadow);
}

.stories-manager__stories-grid--dragging .stories-manager__story-card:not(.stories-manager__story-card--dragging) {
  transition: transform 0.2s cubic-bezier(0.2, 0, 0, 1);
}

.stories-manager__story-card--dragging {
  opacity: 0.5;
  transform: scale(0.92) !important;
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.2) !important;
  z-index: 100;
  position: relative;
}

.stories-manager__story-drag-handle {
  position: absolute;
  top: 8px;
  right: 8px;
  z-index: 10;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(8px);
  border-radius: 8px;
  color: white;
  opacity: 0;
  cursor: grab;
  transition: opacity 0.2s ease, transform 0.2s ease, background 0.2s ease;
}

.stories-manager__story-card:hover .stories-manager__story-drag-handle {
  opacity: 1;
}

.stories-manager__story-drag-handle:hover {
  background: var(--color-accent);
  transform: scale(1.1);
}

.stories-manager__story-drag-handle:active {
  cursor: grabbing;
  transform: scale(1.05);
}

.stories-manager__story-media {
  position: relative;
  aspect-ratio: 9/16;
  background: var(--color-bg-tertiary);
}

.stories-manager__story-media img,
.stories-manager__story-media video {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

/* Checkbox в верхнем левом углу карточки */
.stories-manager__story-checkbox {
  position: absolute;
  top: 0.375rem;
  left: 0.375rem;
  width: 20px;
  height: 20px;
  background: rgba(255, 255, 255, 0.9);
  border: 2px solid rgba(0, 0, 0, 0.3);
  border-radius: 4px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  z-index: 2;
}

.stories-manager__story-checkbox:hover {
  border-color: var(--color-accent);
  transform: scale(1.1);
}

.stories-manager__story-checkbox--checked {
  background: var(--color-accent);
  border-color: var(--color-accent);
}

.stories-manager__story-checkbox--checked .iconify {
  color: white;
  font-size: 14px;
}

/* iOS-style toggle в верхнем правом углу */
.stories-manager__story-toggle {
  position: absolute;
  top: 0.375rem;
  right: 0.375rem;
  z-index: 2;
}

.ios-toggle {
  display: inline-block;
  position: relative;
  width: 36px;
  height: 20px;
  cursor: pointer;
}

.ios-toggle input {
  opacity: 0;
  width: 0;
  height: 0;
}

.ios-toggle__slider {
  position: absolute;
  inset: 0;
  background: rgba(120, 120, 128, 0.32);
  border-radius: 20px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.ios-toggle__slider::before {
  content: '';
  position: absolute;
  width: 16px;
  height: 16px;
  left: 2px;
  bottom: 2px;
  background: white;
  border-radius: 50%;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.ios-toggle input:checked + .ios-toggle__slider {
  background: #34c759;
}

.ios-toggle input:checked + .ios-toggle__slider::before {
  transform: translateX(16px);
}

/* Выделенная карточка */
.stories-manager__story-card--selected {
  outline: 2px solid var(--color-accent);
  outline-offset: -2px;
}

.stories-manager__story-card--selected .stories-manager__story-media::after {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(var(--color-accent-rgb), 0.1);
  pointer-events: none;
}

/* Карточка кликабельна */
.stories-manager__story-card {
  cursor: pointer;
}

.stories-manager__story-footer {
  padding: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.25rem;
}

.stories-manager__story-name {
  font-size: 0.75rem;
  font-weight: 500;
  color: var(--color-text-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.stories-manager__story-actions {
  display: flex;
  gap: 0.25rem;
  flex-shrink: 0;
}

.stories-manager__story-btn {
  width: 28px !important;
  height: 28px !important;
}

.stories-manager__story-btn .iconify {
  font-size: 1rem !important;
}

.stories-manager__delete-group-btn {
  width: 36px !important;
  height: 36px !important;
}

.stories-manager__delete-group-btn .iconify {
  font-size: 1.25rem !important;
}

/* ============== NEWS MANAGER ============== */
.news-manager {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.news-manager__loading,
.news-manager__empty {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  color: var(--color-text-muted);
  min-height: 300px;
}

.news-manager__empty .iconify {
  font-size: 3rem;
  opacity: 0.5;
}

.news-manager__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 1.25rem;
}

.news-manager__search {
  display: flex;
  align-items: center;
  gap: 1rem;
  flex: 1;
}

.news-manager__search-input {
  min-width: 280px;
  max-width: 400px;
  flex: 1;
}

.news-manager__search-count {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

.news-manager__header-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-shrink: 0;
}

.news-manager__grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.25rem;
}

.news-manager__card {
  background: var(--color-bg-card);
  border-radius: 0.75rem;
  overflow: hidden;
  border: 1px solid var(--color-border);
  transition: all 0.2s ease;
  display: flex;
  flex-direction: column;
}

.news-manager__card {
  transition: transform 0.2s cubic-bezier(0.2, 0, 0, 1), 
              box-shadow 0.2s ease, 
              opacity 0.2s ease,
              border-color 0.2s ease;
  cursor: pointer;
}

.news-manager__card:hover {
  border-color: var(--color-accent);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
}

.news-manager__card:active {
  cursor: grabbing;
}

/* Drag & Drop стили для новостей */
.news-manager__grid--dragging .news-manager__card:not(.news-manager__card--dragging) {
  transition: transform 0.2s cubic-bezier(0.2, 0, 0, 1);
}

.news-manager__card--dragging {
  opacity: 0.5;
  transform: scale(0.95);
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.15);
  z-index: 100;
  position: relative;
}

/* Анимация удаления/добавления для TransitionGroup */
.news-grid-move,
.news-grid-enter-active,
.news-grid-leave-active {
  transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
}

.news-grid-enter-from {
  opacity: 0;
  transform: scale(0.8);
}

.news-grid-leave-to {
  opacity: 0;
  transform: scale(0.8);
}

/* Убираем из потока уходящий элемент чтобы остальные плавно сдвинулись */
.news-grid-leave-active {
  position: absolute;
}

/* Плавная анимация для переключения режимов (архив/обычный) */
.news-fade-enter-active,
.news-fade-leave-active {
  transition: opacity 0.25s ease;
}

.news-fade-enter-from,
.news-fade-leave-to {
  opacity: 0;
}

.news-fade-move {
  transition: none;
}

.news-fade-leave-active {
  position: absolute;
  opacity: 0;
  transition: none;
}

.news-manager__card--inactive {
  opacity: 0.6;
}

.news-manager__card--archived {
  border-color: var(--color-warning);
  opacity: 0.85;
}

.news-manager__card--archived:hover {
  border-color: var(--color-warning);
}

.news-manager__card--selected {
  border-color: var(--color-accent);
  box-shadow: 0 0 0 2px var(--color-accent);
}

.news-manager__card-image {
  position: relative;
  aspect-ratio: 3 / 4;
  background: var(--color-bg-tertiary);
  overflow: hidden;
}

.news-manager__card-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.news-manager__card-image-empty {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-text-muted);
}

.news-manager__card-image-empty .iconify {
  font-size: 3rem;
  opacity: 0.3;
}

/* Чекбокс для выбора новостей */
.news-manager__card-checkbox {
  position: absolute;
  top: 0.75rem;
  right: 0.75rem;
  width: 22px;
  height: 22px;
  border-radius: 6px;
  border: 2px solid rgba(255, 255, 255, 0.7);
  background: rgba(0, 0, 0, 0.3);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
  opacity: 0;
  z-index: 10;
  backdrop-filter: blur(4px);
}

.news-manager__card:hover .news-manager__card-checkbox,
.news-manager__card-checkbox--checked {
  opacity: 1;
}

.news-manager__card-checkbox:hover {
  border-color: var(--color-accent);
  background: rgba(0, 0, 0, 0.5);
  transform: scale(1.1);
}

.news-manager__card-checkbox--checked {
  background: var(--color-accent);
  border-color: var(--color-accent);
}

.news-manager__card-checkbox--checked .iconify {
  color: white;
  font-size: 14px;
}

.news-manager__card-category-badge {
  position: absolute;
  top: 0.75rem;
  left: 0.75rem;
  padding: 0.25rem 0.625rem;
  background: var(--color-accent);
  color: white;
  font-size: 0.625rem;
  font-weight: 600;
  border-radius: 0.25rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  max-width: calc(100% - 1.5rem);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.news-manager__card-archived-badge {
  position: absolute;
  bottom: 0.75rem;
  right: 0.75rem;
  padding: 0.25rem 0.625rem;
  background: var(--color-warning);
  color: white;
  font-size: 0.625rem;
  font-weight: 600;
  border-radius: 0.25rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.news-manager__card-archived-badge .iconify {
  font-size: 0.75rem;
}

.news-manager__card-inactive-badge {
  position: absolute;
  bottom: 0.75rem;
  right: 0.75rem;
  padding: 0.25rem 0.625rem;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  font-size: 0.6875rem;
  font-weight: 600;
  border-radius: 0.25rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.news-manager__card-content {
  flex: 1;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.news-manager__card-title {
  font-size: 0.9375rem;
  font-weight: 600;
  color: var(--color-text-primary);
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  margin: 0;
}

.news-manager__card-excerpt {
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  margin: 0;
}

.news-manager__card-meta {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-top: auto;
  padding-top: 0.5rem;
}

.news-manager__card-date {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.6875rem;
  color: var(--color-text-muted);
}

.news-manager__card-date .iconify {
  font-size: 0.875rem;
}


.news-manager__card-actions {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.75rem 1rem;
  border-top: 1px solid var(--color-border);
  background: var(--color-bg-secondary);
}

.news-manager__switch {
  transform: scale(0.75);
  transform-origin: left center;
  margin-right: auto;
}

.news-manager__card-btn {
  width: 32px !important;
  height: 32px !important;
}

.news-manager__card-btn .iconify {
  font-size: 1.125rem !important;
}

.news-manager__restore-btn {
  flex: 1;
  font-size: 0.75rem !important;
}

/* ============== BANNERS MANAGER ============== */
.banners-manager {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0;
}

.banners-manager__content {
  flex: 1;
  display: grid;
  grid-template-columns: 280px 1fr;
  gap: 1.5rem;
  min-height: 0;
}

@media (max-width: 900px) {
  .banners-manager__content {
    grid-template-columns: 1fr;
  }
}

/* Preview Panel */
.banners-manager__preview {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.banners-manager__preview-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 0.5rem;
}

.banners-manager__preview-title {
  font-size: 0.8125rem;
  font-weight: 600;
  color: var(--color-text-secondary);
}

.banners-manager__phone {
  display: flex;
  justify-content: center;
}

.banners-manager__phone-frame {
  width: 240px;
  aspect-ratio: 9/19.5;
  background: #0a0a0a;
  border-radius: 32px;
  padding: 6px;
  position: relative;
  box-shadow: 0 20px 60px rgba(0,0,0,0.4), inset 0 0 0 2px #2a2a2a;
  display: flex;
  flex-direction: column;
}

.banners-manager__phone-island {
  width: 70px;
  height: 22px;
  background: #000;
  border-radius: 20px;
  position: absolute;
  top: 10px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 20;
}

.banners-manager__phone-screen {
  flex: 1;
  background: #fafafa;
  border-radius: 26px 26px 0 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

/* App Banner */
.banners-manager__app-banner {
  width: 100%;
  aspect-ratio: 3/4;
  position: relative;
  overflow: hidden;
  flex-shrink: 0;
}

.banners-manager__app-banner-track {
  display: flex;
  height: 100%;
  transition: transform 0.4s ease;
}

.banners-manager__app-banner-slide {
  min-width: 100%;
  height: 100%;
}

.banners-manager__app-banner-slide img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.banners-manager__app-banner-empty {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #e0e0e0, #f5f5f5);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #999;
}

.banners-manager__app-banner-empty .iconify {
  font-size: 2rem;
}

.banners-manager__app-banner-dots {
  position: absolute;
  bottom: 8px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  gap: 4px;
}

.banners-manager__app-banner-dots span {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: rgba(255,255,255,0.5);
  cursor: pointer;
  transition: all 0.2s ease;
}

.banners-manager__app-banner-dots span.active {
  background: white;
  width: 12px;
  border-radius: 3px;
}

/* App Stories Mockup */
.banners-manager__app-stories {
  display: flex;
  gap: 10px;
  padding: 10px 8px;
  background: white;
  flex-shrink: 0;
}

.banners-manager__app-story {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
}

.banners-manager__app-story-ring {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  padding: 2px;
  background: linear-gradient(135deg, #2E7D32, #66BB6A);
}

.banners-manager__app-story-avatar {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  background: linear-gradient(135deg, #e8e8e8, #d0d0d0);
  border: 2px solid white;
}

.banners-manager__app-story span {
  font-size: 6px;
  color: #333;
  max-width: 42px;
  text-align: center;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* App News Mockup */
.banners-manager__app-news {
  flex: 1;
  padding: 6px 8px;
  background: white;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.banners-manager__app-news-header {
  display: flex;
  align-items: center;
  gap: 4px;
}

.banners-manager__app-news-title {
  font-size: 10px;
  font-weight: 700;
  color: #1a1a1a;
  border-left: 2px solid #2E7D32;
  padding-left: 4px;
}

.banners-manager__app-news-filters {
  display: flex;
  gap: 4px;
}

.banners-manager__app-news-filters span {
  font-size: 6px;
  padding: 3px 8px;
  border-radius: 12px;
  background: #f0f0f0;
  color: #666;
}

.banners-manager__app-news-filters span.active {
  background: #1a1a1a;
  color: white;
}

.banners-manager__app-news-card {
  flex: 1;
  background: linear-gradient(135deg, #e8e8e8, #d5d5d5);
  border-radius: 8px;
  min-height: 30px;
}

/* Phone Navbar */
.banners-manager__phone-navbar {
  height: 42px;
  background: white;
  border-radius: 0 0 26px 26px;
  display: flex;
  align-items: center;
  justify-content: space-around;
  padding: 0 4px;
  flex-shrink: 0;
  border-top: 1px solid #f0f0f0;
}

.banners-manager__phone-navbar-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1px;
  color: #999;
}

.banners-manager__phone-navbar-item.active {
  color: #2E7D32;
}

.banners-manager__phone-navbar-item .iconify {
  font-size: 14px;
}

.banners-manager__phone-navbar-item span {
  font-size: 5px;
}

/* List Panel */
.banners-manager__list {
  background: var(--color-bg-card);
  border-radius: 0.75rem;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  min-height: 0;
  overflow: hidden;
}

.banners-manager__list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  flex-shrink: 0;
}

.banners-manager__list-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.banners-manager__loading,
.banners-manager__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 3rem;
  gap: 0.75rem;
  color: var(--color-text-muted);
}

.banners-manager__empty .iconify {
  font-size: 2.5rem;
}

.banners-manager__items {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  overflow-y: auto;
  flex: 1;
  scroll-behavior: smooth;
}

.banners-manager__item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.625rem;
  background: var(--color-bg-secondary);
  border-radius: 0.5rem;
  transition: transform 0.2s cubic-bezier(0.2, 0, 0, 1), 
              background 0.15s ease, 
              opacity 0.2s ease,
              box-shadow 0.2s ease,
              border-color 0.15s ease;
  border: 1px solid transparent;
  cursor: grab;
}

.banners-manager__item:active {
  cursor: grabbing;
}

.banners-manager__item:hover {
  background: var(--color-bg-hover);
}

/* Drag & Drop стили для баннеров */
.banners-manager__items--dragging .banners-manager__item:not(.banners-manager__item--dragging) {
  transition: transform 0.2s cubic-bezier(0.2, 0, 0, 1);
}

.banners-manager__item--dragging {
  opacity: 0.5;
  transform: scale(0.98);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
  z-index: 100;
  position: relative;
  background: var(--color-bg-tertiary);
}

.banners-manager__item--inactive {
  opacity: 0.5;
}

.banners-manager__item--scheduled {
  border-color: var(--color-info);
  background: rgba(var(--color-info-rgb), 0.05);
}

.banners-manager__item--expired {
  border-color: var(--color-error);
  background: rgba(var(--color-error-rgb), 0.05);
}

.banners-manager__item-preview {
  width: 72px;
  height: 96px;
  border-radius: 0.5rem;
  overflow: hidden;
  flex-shrink: 0;
  position: relative;
  background: var(--color-bg-tertiary);
  cursor: pointer;
  border: 2px dashed transparent;
  transition: all 0.15s ease;
}

.banners-manager__item-preview:hover {
  border-color: var(--color-accent);
}

.banners-manager__item-preview img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.banners-manager__item-preview-empty {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.25rem;
  color: var(--color-text-muted);
}

.banners-manager__item-preview-empty .iconify {
  font-size: 1.5rem;
}

.banners-manager__item-preview-empty span {
  font-size: 0.5rem;
}

.banners-manager__item-preview-overlay {
  position: absolute;
  inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.15s ease;
}

.banners-manager__item-preview:hover .banners-manager__item-preview-overlay {
  opacity: 1;
}

.banners-manager__item-preview-overlay .iconify {
  font-size: 1.25rem;
  color: white;
}

.banners-manager__item-form {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.banners-manager__item-name-row {
  display: flex;
  align-items: center;
  gap: 0.375rem;
}

.banners-manager__item-name {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text-primary);
  cursor: pointer;
  padding: 0.25rem 0;
  border-radius: 0.25rem;
  transition: background 0.15s ease;
}

.banners-manager__item-name:hover {
  background: var(--color-bg-hover);
  padding: 0.25rem 0.5rem;
  margin: 0 -0.5rem;
}

.banners-manager__item-edit-btn {
  opacity: 0.5;
  transition: opacity 0.15s ease;
}

.banners-manager__item:hover .banners-manager__item-edit-btn {
  opacity: 1;
}

.banners-manager__item-edit-btn .iconify {
  font-size: 0.875rem !important;
}

.banners-manager__item-input {
  flex: 1;
  padding: 0.375rem 0.625rem;
  border: 1px solid var(--color-accent);
  border-radius: 0.375rem;
  background: var(--color-bg-card);
  color: var(--color-text-primary);
  font-size: 0.875rem;
  font-weight: 600;
  outline: none;
}

.banners-manager__item-input::placeholder {
  color: var(--color-text-muted);
  font-weight: 400;
}

/* Города как бейджики */
.banners-manager__item-cities-badges {
  display: flex;
  flex-wrap: wrap;
  gap: 0.375rem;
  flex: 1;
}

.banners-manager__city-badge {
  padding: 0.25rem 0.625rem;
  font-size: 0.6875rem;
  font-weight: 500;
  border-radius: 1rem;
  border: 1px solid var(--color-border);
  background: transparent;
  color: var(--color-text-muted);
  cursor: pointer;
  transition: all 0.15s ease;
  white-space: nowrap;
}

/* Неактивный бейджик - hover */
.banners-manager__city-badge:hover {
  border-color: var(--color-accent);
  color: var(--color-accent);
  background: rgba(var(--color-accent-rgb), 0.1);
}

/* Активный бейджик */
.banners-manager__city-badge--active {
  background: var(--color-accent);
  border-color: var(--color-accent);
  color: white;
}

/* Активный бейджик - hover (светлее) */
.banners-manager__city-badge--active:hover {
  background: rgba(var(--color-accent-rgb), 0.75);
  border-color: rgba(var(--color-accent-rgb), 0.75);
  color: white;
}

.banners-manager__item-period-section {
  flex-shrink: 0;
}

.banners-manager__item-period-btn {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.375rem 0.625rem;
  background: var(--color-bg-secondary);
  border-radius: 0.375rem;
  font-size: 0.6875rem;
  color: var(--color-text-secondary);
  cursor: pointer;
  transition: all 0.15s ease;
  white-space: nowrap;
}

.banners-manager__item-period-btn:hover {
  background: var(--color-bg-hover);
}

.banners-manager__item-period-btn .iconify {
  font-size: 0.875rem;
}

.banners-manager__item-controls {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  flex-shrink: 0;
}

/* Уменьшенный switch */
.banners-manager__switch {
  transform: scale(0.75);
  transform-origin: center;
  margin: 0 -4px;
}

.banners-manager__item-btn {
  width: 32px !important;
  height: 32px !important;
}

.banners-manager__item-btn .iconify {
  font-size: 1.125rem !important;
}

/* Новый баннер */
.banners-manager__item--new {
  border-style: dashed;
  border-color: var(--color-accent);
  background: rgba(var(--color-accent-rgb), 0.05);
}

.banners-manager__add-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 1rem;
  border: 2px dashed var(--color-border);
  border-radius: 0.5rem;
  color: var(--color-text-muted);
  cursor: pointer;
  transition: all 0.15s ease;
}

.banners-manager__add-btn:hover {
  border-color: var(--color-accent);
  color: var(--color-accent);
  background: rgba(var(--color-accent-rgb), 0.05);
}

.banners-manager__add-btn .iconify {
  font-size: 1.25rem;
}

.banners-manager__add-btn span {
  font-size: 0.8125rem;
  font-weight: 500;
}

/* Модальное окно изображения */
.banner-image-dialog {
  background: var(--color-bg-card) !important;
}

.banner-image-dialog__title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 1.125rem;
  font-weight: 600;
  padding: 1rem 1.25rem;
  color: var(--color-text-primary);
}

.banner-image-dialog__title .iconify {
  font-size: 1.25rem;
  color: var(--color-accent);
}

.banner-image-dialog__content {
  padding: 0 1.25rem 1rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.banner-image-dialog__input {
  min-height: 300px;
}

.banner-image-dialog__dropzone {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 2rem;
  color: var(--color-text-muted);
}

.banner-image-dialog__dropzone .iconify {
  font-size: 3rem;
}

.banner-image-dialog__hint {
  font-size: 0.75rem;
  opacity: 0.7;
}

.banner-image-dialog__hint-video {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  margin-top: 0.5rem;
  padding: 0.375rem 0.75rem;
  font-size: 0.6875rem;
  color: var(--color-accent);
  background: rgba(var(--color-accent-rgb), 0.1);
  border-radius: 1rem;
}

.banner-image-dialog__hint-video .iconify {
  font-size: 0.875rem;
}

.banner-image-dialog__actions {
  padding: 0.75rem 1.25rem 1.25rem;
  justify-content: flex-end;
  gap: 0.5rem;
}

/* Period Menu */
.banners-manager__period-menu {
  padding: 0.75rem;
  min-width: 240px;
}

.banners-manager__period-presets,
.banners-manager__period-custom {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.banners-manager__period-label {
  font-size: 0.6875rem;
  font-weight: 600;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.banners-manager__period-buttons {
  display: flex;
  gap: 0.375rem;
}

.banners-manager__period-dates {
  display: flex;
  gap: 0.5rem;
}

/* Story dialog */
.story-dialog {
  background: var(--color-bg-card) !important;
  overflow: hidden;
}

.story-dialog .v-card-text {
  overflow: visible !important;
}

.story-dialog__title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 1.125rem;
  font-weight: 600;
  padding: 1rem 1.5rem;
  color: var(--color-text-primary);
}

.story-dialog__title .iconify {
  font-size: 1.25rem;
  color: var(--color-accent);
}

.story-dialog__content {
  padding: 0 1.5rem 1rem;
  overflow: visible;
}

.story-dialog__layout {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

@media (min-width: 540px) {
  .story-dialog__layout {
    flex-direction: row;
    gap: 1.5rem;
  }
}

/* Левая часть - медиа */
.story-dialog__left {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
}

@media (min-width: 540px) {
  .story-dialog__left {
    flex-shrink: 0;
  }
}

.story-dialog__type-switch {
  display: flex;
  justify-content: center;
}

.story-dialog__media-upload {
  width: 180px;
  aspect-ratio: 9/16;
  background: var(--color-bg-secondary);
  border: 2px dashed var(--color-border);
  border-radius: 0.75rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  cursor: pointer;
  transition: all 0.15s ease;
  overflow: hidden;
  position: relative;
}

.story-dialog__media-upload:hover {
  border-color: var(--color-accent);
  background: var(--color-bg-hover);
}

.story-dialog__media-upload--has-media {
  border-style: solid;
  border-color: var(--color-accent);
}

.story-dialog__media-upload .iconify {
  font-size: 2.5rem;
  color: var(--color-text-muted);
}

.story-dialog__media-upload > span {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

.story-dialog__format-hint {
  font-size: 0.6875rem !important;
  color: var(--color-text-muted);
  opacity: 0.7;
  background: var(--color-bg-tertiary);
  padding: 0.125rem 0.5rem;
  border-radius: 0.25rem;
}

.story-dialog__media-upload img,
.story-dialog__media-upload video {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.story-dialog__media-overlay {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.15s ease;
}

.story-dialog__media-upload:hover .story-dialog__media-overlay {
  opacity: 1;
}

.story-dialog__media-overlay .iconify {
  font-size: 1.75rem;
  color: white;
}

/* Правая часть - настройки */
.story-dialog__right {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 1rem;
  min-width: 0;
}

@media (min-width: 540px) {
  .story-dialog__right {
    padding-top: 0.5rem;
  }
}

.story-dialog__field {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
}

.story-dialog__label {
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--color-text-secondary);
}

/* Бейджики городов для историй */
.story-dialog__cities-badges {
  display: flex;
  flex-wrap: wrap;
  gap: 0.375rem;
}

.story-dialog__city-badge {
  padding: 0.375rem 0.75rem;
  font-size: 0.75rem;
  font-weight: 500;
  border-radius: 1rem;
  border: 1px solid var(--color-border);
  background: transparent;
  color: var(--color-text-muted);
  cursor: pointer;
  transition: all 0.15s ease;
}

.story-dialog__city-badge:hover {
  border-color: var(--color-accent);
  color: var(--color-accent);
  background: rgba(var(--color-accent-rgb), 0.1);
}

.story-dialog__city-badge--active {
  background: var(--color-accent);
  border-color: var(--color-accent);
  color: white;
}

.story-dialog__city-badge--active:hover {
  background: rgba(var(--color-accent-rgb), 0.75);
  border-color: rgba(var(--color-accent-rgb), 0.75);
  color: white;
}

.story-dialog__field--switch {
  margin-top: 0.5rem;
}

.story-dialog__switch {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.story-dialog__switch-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text-primary);
}

.story-dialog__actions {
  padding: 0.75rem 1.5rem 1.25rem;
  justify-content: flex-end;
  gap: 0.5rem;
}

/* Fix overflow issues */
.story-dialog :deep(.v-card-text) {
  overflow: visible !important;
  padding-top: 0 !important;
}

.story-dialog :deep(.v-card__content) {
  overflow: visible !important;
}

/* ============== CROP DIALOG STYLES ============== */
.crop-dialog {
  border-radius: 1rem !important;
  background-color: var(--color-bg-card) !important;
  color: var(--color-text-primary) !important;
}

.crop-dialog__title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 1.25rem;
  font-weight: 600;
  padding: 1.25rem 1.5rem;
  color: var(--color-text-primary);
}

.crop-dialog__title .iconify {
  font-size: 1.5rem;
  color: var(--color-accent);
}

.crop-dialog__ratio {
  margin-left: auto;
  padding: 0.25rem 0.75rem;
  font-size: 0.75rem;
  font-weight: 600;
  background: var(--color-accent);
  color: var(--color-bg-card);
  border-radius: 1rem;
}

.crop-dialog__container {
  max-width: 100%;
  max-height: 500px;
  overflow: hidden;
  border-radius: 0.5rem;
  background: #000;
}

.crop-dialog__image {
  max-width: 100%;
  display: block;
}

.crop-dialog__loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 2rem;
  color: var(--color-text-secondary);
}

.crop-dialog__actions {
  padding: 1rem 1.5rem;
  justify-content: flex-end;
  gap: 0.5rem;
  background-color: var(--color-bg-card);
}

.crop-dialog__actions .v-btn .iconify {
  margin-right: 0.25rem;
}

/* ============== SHOPS MANAGER ============== */
.shops-manager {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.shops-manager__header {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

@media (min-width: 640px) {
  .shops-manager__header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
  }
}

.shops-manager__search {
  display: flex;
  align-items: center;
  gap: 1rem;
  flex: 1;
  max-width: 400px;
}

.shops-manager__search-input {
  flex: 1;
}

.shops-manager__search-count {
  font-size: 0.875rem;
  color: var(--color-text-secondary);
  white-space: nowrap;
}

.shops-manager__loading,
.shops-manager__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 4rem 2rem;
  color: var(--color-text-secondary);
}

.shops-manager__loading .iconify,
.shops-manager__empty .iconify {
  font-size: 4rem;
  opacity: 0.3;
}

.shops-manager__grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1.5rem;
}

@media (min-width: 640px) {
  .shops-manager__grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1024px) {
  .shops-manager__grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (min-width: 1400px) {
  .shops-manager__grid {
    grid-template-columns: repeat(4, 1fr);
  }
}

/* Shop Card */
.shop-card {
  position: relative;
  display: flex;
  flex-direction: column;
  background: var(--color-bg-secondary);
  border-radius: 1rem;
  overflow: hidden;
  transition: all 0.3s ease;
  box-shadow: 0 4px 6px -1px var(--color-shadow);
}

.shop-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 20px 25px -5px var(--color-shadow);
}

.shop-card--inactive {
  opacity: 0.7;
}

.shop-card__image {
  position: relative;
  width: 100%;
  aspect-ratio: 16 / 10;
  overflow: hidden;
  background: linear-gradient(135deg, var(--color-bg-tertiary), var(--color-bg-secondary));
}

.shop-card__image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}

.shop-card:hover .shop-card__image img {
  transform: scale(1.05);
}

.shop-card__image-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  color: var(--color-text-muted);
}

.shop-card__image-placeholder .iconify {
  font-size: 3rem;
  opacity: 0.3;
}

.shop-card__status-badge {
  position: absolute;
  top: 0.75rem;
  right: 0.75rem;
  display: flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.25rem 0.75rem;
  background: rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(8px);
  border-radius: 999px;
  color: #fff;
  font-size: 0.75rem;
  font-weight: 500;
}

.shop-card__content {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  padding: 1rem;
}

.shop-card__header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 0.5rem;
}

.shop-card__title {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text-primary);
  margin: 0;
  line-height: 1.3;
}

.shop-card__info {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
}

.shop-card__info-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.875rem;
  color: var(--color-text-secondary);
}

.shop-card__info-row .iconify {
  font-size: 1rem;
  color: var(--color-accent);
  flex-shrink: 0;
}

.shop-card__info-row--secondary {
  padding-left: 1.5rem;
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

/* Social buttons */
.shop-card__socials {
  display: flex;
  gap: 0.5rem;
  padding-top: 0.5rem;
  border-top: 1px solid var(--color-border);
}

.shop-card__social {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.25rem;
  padding: 0.5rem 0.75rem;
  border-radius: 0.5rem;
  font-size: 0.8125rem;
  font-weight: 500;
  text-decoration: none;
  transition: all 0.2s ease;
  border: none;
  cursor: pointer;
}

.shop-card__social .iconify {
  font-size: 1.125rem;
}

.shop-card__social--instagram {
  background: linear-gradient(135deg, #833ab4, #fd1d1d, #fcb045);
  color: #fff;
}

.shop-card__social--instagram:hover {
  transform: scale(1.05);
  box-shadow: 0 4px 12px rgba(131, 58, 180, 0.4);
}

.shop-card__social--2gis {
  background: linear-gradient(135deg, #0db14b, #0a9040);
  color: #fff;
}

.shop-card__social--2gis:hover {
  transform: scale(1.05);
  box-shadow: 0 4px 12px rgba(13, 177, 75, 0.4);
}

.shop-card__social--whatsapp {
  background: linear-gradient(135deg, #25d366, #128c7e);
  color: #fff;
}

.shop-card__social--whatsapp:hover {
  transform: scale(1.05);
  box-shadow: 0 4px 12px rgba(37, 211, 102, 0.4);
}

.shop-card__social--disabled {
  background: var(--color-bg-tertiary);
  color: var(--color-text-muted);
  cursor: not-allowed;
  opacity: 0.5;
}

.shop-card__social--disabled:hover {
  transform: none;
  box-shadow: none;
}

.shop-card__actions {
  display: flex;
  justify-content: space-between;
  padding-top: 0.5rem;
}

.shop-card__actions .v-btn .iconify {
  margin-right: 0.25rem;
}

/* Shop Card Animation */
.shop-card-enter-active,
.shop-card-leave-active {
  transition: all 0.3s ease;
}

.shop-card-enter-from {
  opacity: 0;
  transform: translateY(20px);
}

.shop-card-leave-to {
  opacity: 0;
  transform: scale(0.95);
}

.shop-card-move {
  transition: transform 0.3s ease;
}

/* Shop Modal */
.shop-modal {
  background-color: var(--color-bg-card);
}

.shop-modal__title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1.25rem 1.5rem;
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--color-text-primary);
  border-bottom: 1px solid var(--color-border);
}

.shop-modal__title .iconify {
  font-size: 1.5rem;
  color: var(--color-accent);
}

.shop-modal__content {
  padding: 1.5rem !important;
}

.shop-modal__grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1.5rem;
  margin-bottom: 1.5rem;
}

@media (min-width: 500px) {
  .shop-modal__grid {
    grid-template-columns: 180px 1fr;
  }
}

.shop-modal__image-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}

.shop-modal__image-upload {
  width: 180px;
  height: 120px;
  border-radius: 0.75rem;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.2s ease;
  border: 2px dashed var(--color-border);
}

.shop-modal__image-upload:hover {
  border-color: var(--color-accent);
  background-color: var(--color-bg-tertiary);
}

.shop-modal__image-upload img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.shop-modal__image-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  width: 100%;
  height: 100%;
  color: var(--color-text-muted);
}

.shop-modal__image-placeholder .iconify {
  font-size: 2rem;
}

.shop-modal__image-placeholder span {
  font-size: 0.75rem;
}

.shop-modal__fields {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.shop-modal__socials-section {
  margin-bottom: 1rem;
}

.shop-modal__section-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1rem;
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text-secondary);
}

.shop-modal__section-title .iconify {
  font-size: 1.125rem;
}

.shop-modal__social-fields {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.shop-modal__social-icon {
  font-size: 1.25rem;
}


.shop-modal__social-icon--2gis {
  color: #0db14b;
}

.shop-modal__social-icon--whatsapp {
  color: #25d366;
}

.shop-modal__status-section {
  padding: 1rem;
  background-color: var(--color-bg-tertiary);
  border-radius: 0.75rem;
}

.shop-modal__actions {
  padding: 1rem 1.5rem;
  border-top: 1px solid var(--color-border);
  background-color: var(--color-bg-card);
}

/* ============== SHOPS MANAGER ACTIONS ============== */
.shops-manager__actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.shops-manager__cities-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--color-text-secondary);
  border-color: var(--color-border);
}

.shops-manager__cities-btn:hover {
  color: var(--color-primary);
  border-color: var(--color-primary);
}

.shops-manager__cities-icon {
  font-size: 1.125rem;
}

/* ============== CITIES MODAL ============== */
.cities-modal {
  background-color: var(--color-bg-card);
}

.cities-modal__title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 1.25rem;
  font-weight: 600;
  padding: 1.25rem 1.5rem;
  border-bottom: 1px solid var(--color-border);
}

.cities-modal__title .iconify {
  font-size: 1.5rem;
  color: var(--color-primary);
}

.cities-modal__content {
  padding: 1.5rem !important;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.cities-modal__add-form {
  display: flex;
  gap: 0.75rem;
  align-items: flex-start;
}

.cities-modal__add-fields {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  flex: 1;
}

@media (min-width: 480px) {
  .cities-modal__add-fields {
    flex-direction: row;
    gap: 0.75rem;
  }
}

.cities-modal__input {
  flex: 1;
  min-width: 0;
}

.cities-modal__input--phone {
  max-width: 160px;
}

@media (max-width: 479px) {
  .cities-modal__input--phone {
    max-width: none;
  }
}

.cities-modal__list-container {
  min-height: 200px;
  max-height: 400px;
  overflow-y: auto;
}

.cities-modal__loading,
.cities-modal__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 3rem 1rem;
  color: var(--color-text-secondary);
}

.cities-modal__loading .iconify,
.cities-modal__empty .iconify {
  font-size: 3rem;
  opacity: 0.4;
}

.cities-modal__list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.cities-modal__item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.875rem 1rem;
  background-color: var(--color-bg-subtle);
  border-radius: 12px;
  transition: all 0.2s ease;
}

.cities-modal__item:hover {
  background-color: var(--color-bg-hover);
}

.cities-modal__item--editing {
  background-color: var(--color-bg-hover);
  box-shadow: 0 0 0 2px var(--color-primary);
}

.cities-modal__item-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  flex: 1;
  min-width: 0;
}

.cities-modal__item-name {
  font-weight: 500;
  color: var(--color-text-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.cities-modal__item-phone {
  font-size: 0.875rem;
  color: var(--color-text-secondary);
}

.cities-modal__item-actions {
  display: flex;
  gap: 0.25rem;
  opacity: 0;
  transition: opacity 0.2s ease;
}

.cities-modal__item:hover .cities-modal__item-actions,
.cities-modal__item--editing .cities-modal__item-actions {
  opacity: 1;
}

.cities-modal__item-edit {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  flex: 1;
}

@media (min-width: 480px) {
  .cities-modal__item-edit {
    flex-direction: row;
    gap: 0.75rem;
  }
}

.cities-modal__edit-input {
  flex: 1;
  min-width: 0;
  padding: 0.5rem 0.75rem;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  background-color: var(--color-bg-card);
  color: var(--color-text-primary);
  font-size: 0.875rem;
  outline: none;
  transition: border-color 0.2s ease;
}

.cities-modal__edit-input:focus {
  border-color: var(--color-primary);
}

.cities-modal__edit-input--phone {
  max-width: 140px;
}

@media (max-width: 479px) {
  .cities-modal__edit-input--phone {
    max-width: none;
  }
}

.cities-modal__actions {
  padding: 1rem 1.5rem;
  border-top: 1px solid var(--color-border);
  background-color: var(--color-bg-card);
}
</style>
