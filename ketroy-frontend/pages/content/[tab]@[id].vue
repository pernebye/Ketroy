<template>
  <div class="content-edit">
    <div class="content-edit__header">
      <v-breadcrumbs :items="brItems" class="content-edit__breadcrumbs">
        <template v-slot:divider>
          <icon name="bi:caret-right-fill" :color="styles.greySemiDark"/>
        </template>
      </v-breadcrumbs>
      <div class="content-edit__actions">
        <btn v-if="route.params.id!=='new'" text="Удалить" class="content-edit__delete-btn"
             prepend-icon="mdi-delete" @click="onDelete"/>
        <btn text="Сохранить" prepend-icon="mdi-plus" :loading="loading" @click="save"/>
      </div>
    </div>
  <v-form ref="form" class="content-edit__form">
    <fade>
      <section v-if="which === 'news'" class="news-editor">
        <!-- Левая колонка: Обложка -->
        <aside class="news-editor__sidebar">
          <div class="news-editor__cover-card">
            <div class="news-editor__cover-header">
              <div class="news-editor__cover-title">
                <icon name="mdi:image-outline" size="20" />
                <span>Обложка новости</span>
              </div>
              <v-btn
                v-if="objNews.blocks[0].file"
                variant="text"
                size="small"
                color="error"
                @click="objNews.blocks[0].file = null; image = [];"
              >
                <icon name="mdi:delete-outline" size="18" />
              </v-btn>
            </div>
            
            <div class="news-editor__cover-content">
              <fade>
                <file-input 
                  v-if="!objNews.blocks[0].file" 
                  v-model="image" 
                  class="news-editor__cover-dropzone"
                  accept="image/*" 
                  :rules="[rules.requiredFile]" 
                  :aspect-ratio="3/4" 
                  @handle-photo-upload="onCoverUpload"
                >
                  <div class="news-editor__dropzone-content">
                    <div class="news-editor__dropzone-icon">
                      <icon name="mdi:cloud-upload-outline" size="32" :color="styles.primary" />
                    </div>
                    <p class="news-editor__dropzone-text">Перетащите изображение</p>
                    <p class="news-editor__dropzone-hint">или нажмите для выбора</p>
                    <span class="news-editor__dropzone-formats">JPG, PNG, WebP • до 10MB</span>
                  </div>
                </file-input>
              </fade>
              <fade>
                <div v-if="objNews.blocks[0].file" class="news-editor__cover-preview">
                  <img 
                    :src="objNews.blocks[0].file" 
                    alt="Обложка" 
                    class="news-editor__cover-image"
                    draggable="false"
                  />
                </div>
              </fade>
            </div>
          </div>

          <!-- Статус публикации -->
          <div class="news-editor__status-card">
            <div class="news-editor__status-header">
              <span>Статус публикации</span>
            </div>
            <div class="news-editor__status-toggle">
              <v-switch 
                inset 
                v-model="objNews.is_active"
                color="#20C933"
                hide-details
              />
              <span :class="['news-editor__status-label', { 'news-editor__status-label--active': objNews.is_active }]">
                {{ objNews.is_active ? 'Опубликовано' : 'Черновик' }}
              </span>
            </div>
          </div>
        </aside>

        <!-- Правая колонка: Основной контент -->
        <main class="news-editor__main">
          <!-- Основная информация -->
          <div class="news-editor__card">
            <div class="news-editor__card-header">
              <icon name="mdi:text-box-outline" size="22" />
              <h3>Основная информация</h3>
            </div>
            
            <div class="news-editor__form-grid">
              <div class="news-editor__field news-editor__field--full">
                <label class="news-editor__label">Заголовок новости</label>
                <v-text-field
                  v-model.trim="objNews.name"
                  density="compact"
                  variant="outlined"
                  :bg-color="styles.greyLight"
                  placeholder="Введите привлекательный заголовок..."
                  rounded="lg"
                  :rules="[rules.requiredText]"
                />
              </div>

              <div class="news-editor__field news-editor__field--full">
                <label class="news-editor__label">Города</label>
                <div class="news-editor__chips-container">
                  <v-chip
                    :color="objNews.city.includes('Все') ? 'primary' : 'default'"
                    :variant="objNews.city.includes('Все') ? 'flat' : 'outlined'"
                    size="small"
                    class="news-editor__chip"
                    @click="toggleCity('Все')"
                  >
                    Все
                  </v-chip>
                  <v-chip
                    v-for="city in citiesForSelection"
                    :key="city.name"
                    :color="isCitySelected(city.name) ? 'primary' : 'default'"
                    :variant="isCitySelected(city.name) ? 'flat' : 'outlined'"
                    size="small"
                    class="news-editor__chip"
                    @click="toggleCity(city.name)"
                  >
                    {{ city.name }}
                  </v-chip>
                </div>
              </div>

              <div class="news-editor__field news-editor__field--full">
                <label class="news-editor__label">Категории</label>
                <div class="news-editor__chips-container">
                  <v-chip
                    :color="objNews.category.includes('Все') ? 'primary' : 'default'"
                    :variant="objNews.category.includes('Все') ? 'flat' : 'outlined'"
                    size="small"
                    class="news-editor__chip"
                    @click="toggleCategory('Все')"
                  >
                    Все
                  </v-chip>
                  <v-chip
                    v-for="category in categoriesForSelection"
                    :key="category.name"
                    :color="isCategorySelected(category.name) ? 'primary' : 'default'"
                    :variant="isCategorySelected(category.name) ? 'flat' : 'outlined'"
                    size="small"
                    class="news-editor__chip"
                    @click="toggleCategory(category.name)"
                  >
                    {{ category.name }}
                  </v-chip>
                </div>
              </div>

              <div class="news-editor__field news-editor__field--full">
                <label class="news-editor__label">Период отображения</label>
                <div class="news-editor__period">
                  <div class="news-editor__period-display" @click="showPeriodMenu = !showPeriodMenu">
                    <Icon name="solar:calendar-outline" />
                    <span v-if="objNews.published_at || objNews.expired_at">
                      {{ objNews.published_at ? formatDisplayDate(objNews.published_at) : 'Сейчас' }}
                      —
                      {{ objNews.expired_at ? formatDisplayDate(objNews.expired_at) : 'Бессрочно' }}
                    </span>
                    <span v-else>Всегда показывать</span>
                    <Icon name="mdi:chevron-down" class="news-editor__period-chevron" :class="{ 'news-editor__period-chevron--open': showPeriodMenu }" />
                  </div>
                  
                  <v-expand-transition>
                    <div v-show="showPeriodMenu" class="news-editor__period-dropdown">
                      <div class="news-editor__period-presets">
                        <span class="news-editor__period-label">Быстрый период</span>
                        <div class="news-editor__period-buttons">
                          <v-btn size="small" variant="tonal" @click="setNewsPeriod(7)">7 дней</v-btn>
                          <v-btn size="small" variant="tonal" @click="setNewsPeriod(14)">14 дней</v-btn>
                          <v-btn size="small" variant="tonal" @click="setNewsPeriod(30)">30 дней</v-btn>
                          <v-btn size="small" variant="tonal" @click="setNewsPeriod(90)">90 дней</v-btn>
                        </div>
                      </div>
                      <v-divider class="my-3" />
                      <div class="news-editor__period-custom">
                        <span class="news-editor__period-label">Свой период</span>
                        <div class="news-editor__period-dates">
                          <v-text-field
                            v-model="objNews.published_at"
                            type="date"
                            density="compact"
                            variant="outlined"
                            :bg-color="styles.greyLight"
                            rounded="lg"
                            hide-details
                            label="С"
                          />
                          <v-text-field
                            v-model="objNews.expired_at"
                            type="date"
                            density="compact"
                            variant="outlined"
                            :bg-color="styles.greyLight"
                            rounded="lg"
                            hide-details
                            label="По"
                          />
                        </div>
                        <v-btn size="small" variant="text" color="error" class="mt-2" @click="clearNewsPeriod">
                          <Icon name="mdi:close" class="mr-1" />
                          Сбросить период
                        </v-btn>
                      </div>
                    </div>
                  </v-expand-transition>
                </div>
              </div>
            </div>

            <!-- Фильтры по размерам (сворачиваемый блок) -->
            <v-expansion-panels variant="accordion" class="news-editor__filters">
              <v-expansion-panel>
                <v-expansion-panel-title class="news-editor__filters-title">
                  <icon name="mdi:filter-variant" size="18" class="mr-2" />
                  Фильтры по размерам (опционально)
                </v-expansion-panel-title>
                <v-expansion-panel-text>
                  <div class="news-editor__filters-grid">
                    <div class="news-editor__field">
                      <label class="news-editor__label">Размер обуви</label>
                      <v-select
                        v-model="objNews.shoe_size"
                        :items="shoe_sizes"
                        density="compact"
                        variant="outlined"
                        :bg-color="styles.greyLight"
                        placeholder="Все размеры"
                        rounded="lg"
                        item-value="value"
                        item-title="label"
                      />
                    </div>
                    <div class="news-editor__field">
                      <label class="news-editor__label">Размер одежды</label>
                      <v-select
                        v-model="objNews.clothing_size"
                        :items="clothing_sizes"
                        density="compact"
                        variant="outlined"
                        :bg-color="styles.greyLight"
                        placeholder="Все размеры"
                        rounded="lg"
                        item-value="value"
                        item-title="label"
                      />
                    </div>
                  </div>
                </v-expansion-panel-text>
              </v-expansion-panel>
            </v-expansion-panels>
          </div>

          <!-- Первый блок контента (описание) -->
          <div class="news-editor__card">
            <div class="news-editor__card-header">
              <icon name="mdi:text" size="22" />
              <h3>Описание</h3>
            </div>
            <v-textarea
              v-model.trim="objNews.blocks[0].text"
              density="compact"
              variant="outlined"
              :bg-color="styles.greyLight"
              placeholder="Напишите интересное описание новости..."
              rounded="lg"
              rows="4"
              :rules="[rules.requiredText]"
            />
          </div>

          <!-- Дополнительные блоки контента -->
          <div class="news-editor__blocks">
            <div class="news-editor__blocks-header">
              <div class="news-editor__blocks-title">
                <icon name="mdi:view-dashboard-outline" size="22" />
                <h3>Контент-блоки</h3>
              </div>
              <div class="news-editor__blocks-actions">
                <v-btn 
                  variant="tonal" 
                  size="small" 
                  color="primary"
                  @click="addImageBlock"
                >
                  <icon name="mdi:image-plus" size="18" class="mr-1" />
                  Медиа
                </v-btn>
                <v-btn 
                  variant="tonal" 
                  size="small"
                  @click="addTextBlock"
                >
                  <icon name="mdi:text-box-plus-outline" size="18" class="mr-1" />
                  Текст
                </v-btn>
              </div>
            </div>

            <div v-if="objNews.blocks.length <= 1" class="news-editor__blocks-empty">
              <icon name="mdi:package-variant" size="48" class="news-editor__blocks-empty-icon" />
              <p>Добавьте блоки для расширенного контента</p>
              <span>Изображения, видео или дополнительный текст</span>
            </div>

            <TransitionGroup name="block-list" tag="div" class="news-editor__blocks-list" :class="{ 'news-editor__blocks-list--dragging': isDraggingBlock }">
              <div 
                v-for="(block, i) in objNews.blocks.slice(1)" 
                :key="'block-' + (i + 1)"
                class="news-editor__block"
                :class="{ 'news-editor__block--dragging': draggingBlockIndex === i && isDraggingBlock }"
                draggable="true"
                @dragstart="onBlockDragStart(i, $event)"
                @dragover="onBlockDragOver(i, $event)"
                @drop="onBlockDrop($event)"
                @dragend="onBlockDragEnd($event)"
              >
                <!-- Текстовый блок -->
                <template v-if="block.text !== undefined && !block.file">
                  <div class="news-editor__block-header">
                    <div class="news-editor__block-header-left">
                      <div class="news-editor__block-drag-handle">
                        <icon name="mdi:drag-vertical" size="20" />
                      </div>
                      <div class="news-editor__block-badge news-editor__block-badge--text">
                        <icon name="mdi:text" size="16" />
                        Текст #{{ i + 1 }}
                      </div>
                    </div>
                    <v-btn
                      variant="text"
                      size="small"
                      color="error"
                      @click="removeBlock(i+1)"
                    >
                      <icon name="mdi:delete-outline" size="18" />
                    </v-btn>
                  </div>
                  <v-textarea
                    v-model.trim="block.text"
                    density="compact"
                    variant="outlined"
                    :bg-color="styles.greyLight"
                    placeholder="Введите текст блока..."
                    rounded="lg"
                    rows="3"
                    :rules="[rules.requiredText]"
                  />
                </template>

                <!-- Медиа блок -->
                <template v-else-if="block.file !== undefined">
                  <div class="news-editor__block-header">
                    <div class="news-editor__block-header-left">
                      <div class="news-editor__block-drag-handle">
                        <icon name="mdi:drag-vertical" size="20" />
                      </div>
                      <div class="news-editor__block-badge news-editor__block-badge--media">
                        <icon name="mdi:image" size="16" />
                        Медиа #{{ i + 1 }}
                      </div>
                    </div>
                    <v-btn
                      variant="text"
                      size="small"
                      color="error"
                      @click="block.file = null; image = []; removeBlock(i+1)"
                    >
                      <icon name="mdi:delete-outline" size="18" />
                    </v-btn>
                  </div>
                  
                  <fade>
                    <file-input 
                      v-if="!block.file" 
                      v-model="image" 
                      class="news-editor__media-dropzone" 
                      accept="image/*,video/*"
                      :rules="[rules.requiredFile]" 
                      @change="onFileChange($event, i + 1)"
                    >
                      <div class="news-editor__dropzone-content news-editor__dropzone-content--compact">
                        <icon name="mdi:cloud-upload-outline" size="28" :color="styles.primary" />
                        <p>Загрузить медиафайл</p>
                        <span>Фото или видео</span>
                      </div>
                    </file-input>
                  </fade>

                  <fade>
                    <div v-if="block.file" class="news-editor__media-preview">
                      <img
                        v-if="isImage(block.file, i+1)"
                        :src="block.file"
                        alt="Медиафайл"
                        class="news-editor__media-image"
                        draggable="false"
                      />
                      <video
                        v-else-if="isVideo(block.file, i + 1)"
                        :src="block.file"
                        controls
                        class="news-editor__media-video"
                        draggable="false"
                      />
                    </div>
                  </fade>
                </template>
              </div>
            </TransitionGroup>
          </div>
        </main>
      </section>
    </fade>
    <fade>
      <section v-if="which === 'shops'" class="content-edit__section">
        <div class="content-edit__sidebar">
          <card-form class="tw-h-fit tw-w-full">
            <p class="tw-mb-2 tw-flex tw-justify-between tw-text-lg tw-font-semibold">
              Фото
              <fade>
                <v-btn
                  v-if="shop.image"
                  variant="plain"
                  icon="mdi-close"
                  density="compact"
                  @click="
                    shop.image = undefined;
                    image = [];
                  "
                >
                  <icon class="tw-cursor-pointer tw-text-3xl" name="mage:trash-square-fill" :color="styles.greyDark"/>
                </v-btn>
              </fade>
            </p>
            <div class="tw-flex tw-grow tw-flex-col">
              <fade>
                <file-input v-if="!shop.image" v-model="image" class="tw-min-h-[230px] tw-grow" accept="image/*"
                            :rules="[rules.requiredFile]" @handlePhotoUpload="handlePhotoUpload">
                  <svg width="44" height="45" viewBox="0 0 44 45" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <rect y="0.5" width="44" height="44" rx="8" :fill="styles.primary"/>
                    <g clip-path="url(#clip0_0_7857)">
                      <path
                        d="M21.3416 22.9017C21.1326 22.6926 20.8845 22.5268 20.6115 22.4136C20.3384 22.3004 20.0457 22.2422 19.7501 22.2422C19.4545 22.2422 19.1618 22.3004 18.8887 22.4136C18.6156 22.5268 18.3675 22.6926 18.1586 22.9017L13.0286 28.0317C13.0979 28.9723 13.5198 29.852 14.2097 30.495C14.8997 31.138 15.807 31.4968 16.7501 31.4997H27.2501C27.9849 31.4996 28.7032 31.2822 29.3148 30.875L21.3416 22.9017Z"
                        fill="white"
                      />
                      <path
                        d="M26.4999 19.5C27.3283 19.5 27.9999 18.8284 27.9999 18C27.9999 17.1716 27.3283 16.5 26.4999 16.5C25.6715 16.5 24.9999 17.1716 24.9999 18C24.9999 18.8284 25.6715 19.5 26.4999 19.5Z"
                        fill="white"
                      />
                      <path
                        d="M27.25 13.5H16.75C15.7558 13.5012 14.8027 13.8967 14.0997 14.5997C13.3967 15.3027 13.0012 16.2558 13 17.25L13 25.9395L17.098 21.8415C17.4462 21.4932 17.8597 21.2169 18.3147 21.0283C18.7697 20.8398 19.2575 20.7428 19.75 20.7428C20.2425 20.7428 20.7303 20.8398 21.1853 21.0283C21.6403 21.2169 22.0538 21.4932 22.402 21.8415L30.3752 29.8148C30.7825 29.2031 30.9999 28.4848 31 27.75V17.25C30.9988 16.2558 30.6033 15.3027 29.9003 14.5997C29.1973 13.8967 28.2442 13.5012 27.25 13.5V13.5ZM26.5 21C25.9067 21 25.3266 20.8241 24.8333 20.4944C24.3399 20.1648 23.9554 19.6962 23.7284 19.1481C23.5013 18.5999 23.4419 17.9967 23.5576 17.4147C23.6734 16.8328 23.9591 16.2982 24.3787 15.8787C24.7982 15.4591 25.3328 15.1734 25.9147 15.0576C26.4967 14.9419 27.0999 15.0013 27.648 15.2284C28.1962 15.4554 28.6648 15.8399 28.9944 16.3333C29.3241 16.8266 29.5 17.4067 29.5 18C29.5 18.7956 29.1839 19.5587 28.6213 20.1213C28.0587 20.6839 27.2956 21 26.5 21Z"
                        fill="white"
                      />
                    </g>
                    <defs>
                      <clipPath id="clip0_0_7857">
                        <rect width="18" height="18" fill="white" transform="translate(13 13.5)"/>
                      </clipPath>
                    </defs>
                  </svg>
                  <span class="tw-mt-4 tw-text-center tw-text-sm tw-text-grey-dark">Перетащите изображение сюда или нажмите «Добавить изображение».</span>
                </file-input>
              </fade>
              <fade>
                <div v-if="shop.image" class="tw-flex tw-grow tw-items-center tw-justify-center">
                  <img :src="shop.image" alt="Hospital Image" class="tw-rounded-lg" draggable="false"/>
                </div>
              </fade>
            </div>
          </card-form>
        </div>

        <div class="content-edit__main">
          <card-form class="content-edit__card">
            <p class="content-edit__card-title">Общая информация</p>
            <div class="content-edit__fields">
              <div class="content-edit__switch-row">
                <v-switch inset v-model="shop.is_active"
                          :label="shop.is_active ? 'Магазин активен' : 'Магазин не активен'" color="#20C933"
                          class="custom-switch"/>
              </div>
              <span class="tw-text-sm">Выберите город </span>
              <v-select
                v-model="shop.city"
                :items="cities"
                density="compact"
                variant="outlined"
                :bg-color="styles.greyLight"
                placeholder="Выберите город"
                :persistent-placeholder="true"
                rounded="lg"
                :rules="[rules.requiredText]"
                item-value="id"
                item-title="name"
              >
                <template v-slot:item="{ props, item }">
                  <v-list-item v-bind="props" :title="''">
                    {{ item.raw.name }}
                  </v-list-item>
                </template>
              </v-select>
              <span class="tw-text-sm">Название </span>
              <v-text-field
                v-model.trim="shop.name"
                density="compact"
                variant="outlined"
                :bg-color="styles.greyLight"
                placeholder="Введите здесь название..."
                rounded="lg"
                :rules="[rules.requiredText]"
              />
              <span class="tw-text-sm">Адрес </span>
              <v-text-field
                v-model.trim="shop.address"
                density="compact"
                variant="outlined"
                :bg-color="styles.greyLight"
                placeholder="Введите здесь адрес магазина . . ."
                rounded="lg"
                :rules="[rules.requiredText]"
              />
              <span class="tw-text-sm">2gis </span>
              <v-text-field
                v-model.trim="shop.two_gis_address"
                density="compact"
                variant="outlined"
                :bg-color="styles.greyLight"
                placeholder="Введите ссылку . . ."
                rounded="lg"
                :rules="[rules.requiredText]"
              />
              <span class="tw-text-sm">Whatsapp </span>
              <v-text-field
                v-model.trim="shop.whatsapp"
                density="compact"
                variant="outlined"
                :bg-color="styles.greyLight"
                placeholder="Введите номер +7 (ХХХ) ХХХ ХХ ХХ"
                rounded="lg"
                :rules="[rules.requiredText]"
                v-maska="'+7##########'"
              />
              <span class="tw-text-sm">Instagram </span>
              <v-text-field
                v-model.trim="shop.instagram"
                density="compact"
                variant="outlined"
                :bg-color="styles.greyLight"
                placeholder="Введите здесь Instagram..."
                rounded="lg"
                :rules="[rules.requiredText]"
              />

              <span class="tw-text-sm">Режим Работы </span>
              <v-textarea
                v-model.trim="shop.opening_hours"
                density="compact"
                variant="outlined"
                :bg-color="styles.greyLight"
                placeholder="Введите здесь режим работы..."
                rounded="lg"
                :rules="[rules.requiredText, rules.maxLength255]"
              />

              <!--              <span class="tw-text-sm">Описание</span>-->
              <!--              <v-textarea-->
              <!--                  v-model.trim="shop.description"-->
              <!--                  density="compact"-->
              <!--                  variant="outlined"-->
              <!--                  :bg-color="styles.greyLight"-->
              <!--                  placeholder="Введите здесь описание..."-->
              <!--                  rounded="lg"-->
              <!--                  :rules="[rules.requiredText]"-->
              <!--              />-->
            </div>
          </card-form>
        </div>
      </section>
    </fade>
    <fade>
      <section v-if="which === 'banners'" class="content-edit__section content-edit__section--tall">
        <div class="content-edit__sidebar">
          <card-form class="tw-h-fit tw-w-full" v-if="banner.type !== 'video'">
            <p class="tw-mb-2 tw-flex tw-justify-between tw-text-lg tw-font-semibold">
              Фото
              <fade>
                <v-btn
                  v-if="banner.image"
                  variant="plain"
                  icon="mdi-close"
                  density="compact"
                  @click="
                    banner.image = undefined;
                    image = [];
                  "
                >
                  <icon class="tw-cursor-pointer tw-text-3xl" name="mage:trash-square-fill" :color="styles.greyDark"/>
                </v-btn>
              </fade>
            </p>
            <div class="tw-flex tw-grow tw-flex-col">
              <fade>
                <file-input v-if="!banner.image" v-model="image" class="tw-min-h-[230px] tw-grow" accept="image/*"
                            :rules="[rules.requiredFile]" :aspect-ratio="3/4" @handlePhotoUpload="handlePhotoUpload">
                  <svg width="44" height="45" viewBox="0 0 44 45" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <rect y="0.5" width="44" height="44" rx="8" :fill="styles.primary"/>
                    <g clip-path="url(#clip0_0_7857)">
                      <path
                        d="M21.3416 22.9017C21.1326 22.6926 20.8845 22.5268 20.6115 22.4136C20.3384 22.3004 20.0457 22.2422 19.7501 22.2422C19.4545 22.2422 19.1618 22.3004 18.8887 22.4136C18.6156 22.5268 18.3675 22.6926 18.1586 22.9017L13.0286 28.0317C13.0979 28.9723 13.5198 29.852 14.2097 30.495C14.8997 31.138 15.807 31.4968 16.7501 31.4997H27.2501C27.9849 31.4996 28.7032 31.2822 29.3148 30.875L21.3416 22.9017Z"
                        fill="white"
                      />
                      <path
                        d="M26.4999 19.5C27.3283 19.5 27.9999 18.8284 27.9999 18C27.9999 17.1716 27.3283 16.5 26.4999 16.5C25.6715 16.5 24.9999 17.1716 24.9999 18C24.9999 18.8284 25.6715 19.5 26.4999 19.5Z"
                        fill="white"
                      />
                      <path
                        d="M27.25 13.5H16.75C15.7558 13.5012 14.8027 13.8967 14.0997 14.5997C13.3967 15.3027 13.0012 16.2558 13 17.25L13 25.9395L17.098 21.8415C17.4462 21.4932 17.8597 21.2169 18.3147 21.0283C18.7697 20.8398 19.2575 20.7428 19.75 20.7428C20.2425 20.7428 20.7303 20.8398 21.1853 21.0283C21.6403 21.2169 22.0538 21.4932 22.402 21.8415L30.3752 29.8148C30.7825 29.2031 30.9999 28.4848 31 27.75V17.25C30.9988 16.2558 30.6033 15.3027 29.9003 14.5997C29.1973 13.8967 28.2442 13.5012 27.25 13.5V13.5ZM26.5 21C25.9067 21 25.3266 20.8241 24.8333 20.4944C24.3399 20.1648 23.9554 19.6962 23.7284 19.1481C23.5013 18.5999 23.4419 17.9967 23.5576 17.4147C23.6734 16.8328 23.9591 16.2982 24.3787 15.8787C24.7982 15.4591 25.3328 15.1734 25.9147 15.0576C26.4967 14.9419 27.0999 15.0013 27.648 15.2284C28.1962 15.4554 28.6648 15.8399 28.9944 16.3333C29.3241 16.8266 29.5 17.4067 29.5 18C29.5 18.7956 29.1839 19.5587 28.6213 20.1213C28.0587 20.6839 27.2956 21 26.5 21Z"
                        fill="white"
                      />
                    </g>
                    <defs>
                      <clipPath id="clip0_0_7857">
                        <rect width="18" height="18" fill="white" transform="translate(13 13.5)"/>
                      </clipPath>
                    </defs>
                  </svg>
                  <span class="tw-mt-4 tw-text-center tw-text-sm tw-text-grey-dark">Перетащите изображение сюда или нажмите «Добавить изображение».</span>
                </file-input>
              </fade>
              <fade>
                <div v-if="banner.image" class="tw-flex tw-grow tw-items-center tw-justify-center">
                  <img :src="banner.image" alt="Hospital Image" class="tw-rounded-lg" draggable="false"/>
                </div>
              </fade>
              <fade>
                <div v-if="compressionInfo" class="compression-info">
                  <h4 class="compression-info__title">Информация о сжатии файла:</h4>
                  <p class="compression-info__text">
                    Исходный размер: <span class="compression-info__value">{{ compressionInfo.originalSize }}</span>
                  </p>
                  <p class="compression-info__text">
                    Сжатый размер: <span class="compression-info__value">{{ compressionInfo.compressedSize }}</span>
                  </p>
                  <div class="compression-info__progress">
                    <div class="compression-info__progress-header">
                      <span>Экономия:</span>
                      <span class="compression-info__percent">{{ compressionInfo.reductionPercent }}%</span>
                    </div>
                    <div class="compression-info__progress-track">
                      <div
                        class="compression-info__progress-bar"
                        :style="{ width: compressionInfo.reductionPercent + '%' }"
                      ></div>
                    </div>
                  </div>
                </div>
              </fade>
            </div>
          </card-form>

          <card-form class="tw-h-fit tw-w-full" v-if="banner.type === 'video'">
            <p class="tw-mb-2 tw-flex tw-justify-between tw-text-lg tw-font-semibold">
              Видео
              <fade>
                <v-btn
                  v-if="banner.video"
                  variant="plain"
                  icon="mdi-close"
                  density="compact"
                  @click="
                    banner.video = undefined;
                    video = [];
                  "
                >
                  <icon class="tw-cursor-pointer tw-text-3xl" name="mage:trash-square-fill" :color="styles.greyDark"/>
                </v-btn>
              </fade>
            </p>
            <div class="tw-flex tw-grow tw-flex-col">
              <fade>
                <file-input
                  v-if="!banner.video"
                  v-model="video"
                  class="tw-min-h-[230px] tw-grow"
                  accept="video/*"
                  :rules="[rules.requiredFile]"
                  @change="handleVideoUpload($event.target.files[0], 'banner')"
                >
                  <svg width="44" height="45" viewBox="0 0 44 45" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <rect y="0.5" width="44" height="44" rx="8" fill="#34460C"/>
                    <path
                      fill-rule="evenodd"
                      clip-rule="evenodd"
                      d="M22 31.5C26.9706 31.5 31 27.4706 31 22.5C31 17.5294 26.9706 13.5 22 13.5C17.0294 13.5 13 17.5294 13 22.5C13 27.4706 17.0294 31.5 22 31.5ZM20.7828 18.4904L26.4265 21.6258C27.1123 22.0068 27.1123 22.9932 26.4265 23.3742L20.7828 26.5096C19.9829 26.9539 19 26.3756 19 25.4606V19.5394C19 18.6244 19.9829 18.0461 20.7828 18.4904Z"
                      fill="white"
                    />
                  </svg>

                  <span class="tw-mt-4 tw-text-center tw-text-sm tw-text-grey-dark">Перетащите видео сюда или нажмите «Добавить видео».</span>
                </file-input>
              </fade>
              <fade>
                <div v-if="banner.video" class="tw-flex tw-grow tw-items-center tw-justify-center">
                  <video :src="banner.video" controls class="tw-rounded-lg" draggable="false"></video>
                </div>
              </fade>
            </div>
          </card-form>
        </div>

        <div class="content-edit__main">
          <card-form class="content-edit__card">
            <p class="content-edit__card-title">Общая информация</p>
            <div class="content-edit__fields">
              <div class="content-edit__switch-row">
                <v-switch v-model="banner.is_active" :label="banner.is_active ? 'Баннер активен' : 'Баннер не активен'"
                          class="custom-switch" color="success" inset/>
              </div>
              <span class="tw-text-sm">Выберите тип медиа-файла</span>
              <v-select
                v-model="banner.type"
                :items="bannersTypes"
                density="compact"
                variant="outlined"
                :bg-color="styles.greyLight"
                placeholder="Выберите тип"
                :persistent-placeholder="true"
                rounded="lg"
                :rules="[rules.requiredText]"
                item-value="value"
                item-title="label"
              >
                <template v-slot:item="{ props, item }">
                  <v-list-item v-bind="props" :title="''">
                    {{ item.title }}
                  </v-list-item>
                </template>
              </v-select>
              <span class="tw-text-sm">Выберите город </span>
              <v-select
                v-model="banner.city"
                :items="cities"
                density="compact"
                variant="outlined"
                :bg-color="styles.greyLight"
                placeholder="Выберите город"
                :persistent-placeholder="true"
                rounded="lg"
                :rules="[rules.requiredText]"
                item-value="id"
                item-title="name"
              >
                <template v-slot:item="{ props, item }">
                  <v-list-item v-bind="props" :title="''">
                    {{ item.raw.name }}
                  </v-list-item>
                </template>
              </v-select>
              <span class="tw-text-sm">Название </span>
              <v-text-field
                v-model.trim="banner.name"
                density="compact"
                variant="outlined"
                :bg-color="styles.greyLight"
                placeholder="Введите здесь название..."
                rounded="lg"
                :rules="[rules.requiredText]"
              />

              <span class="tw-text-sm">Подзоголовок </span>
              <v-text-field
                v-model.trim="banner.subtitle"
                density="compact"
                variant="outlined"
                :bg-color="styles.greyLight"
                placeholder="Введите здесь название..."
                rounded="lg"
                :rules="[rules.requiredText]"
              />
            </div>
          </card-form>
        </div>
      </section>
    </fade>
    <fade>
    </fade>
  </v-form>
  </div>
</template>

<script setup lang="ts">
import {AdminEnums} from '~/types/enums';
import {Quill} from '@vueup/vue-quill';
import '@vueup/vue-quill/dist/vue-quill.snow.css';
import ImageResize from 'quill-image-resize-vue';
import {formatToYYYYMMDD} from '@/utils/formatDate';
import '@vuepic/vue-datepicker/dist/main.css';
import Compressor from 'compressorjs';
import { rules, styles } from '~/composables';


const route = useRoute();
const router = useRouter();
const layoutStore = useLayoutStore();

Quill.register('modules/imageResize', ImageResize);

interface Block {
  text?: string;
  file?: string | null;
  resolution?: string | null;
}

const newCategory = ref('');
const showCategoryInput = ref(false);
const showPeriodMenu = ref(false);

const form = ref();
const image = ref<File[]>([]);
const cover = ref<File[]>([]);
const video = ref<File[]>([]);
// const audio = ref<File[]>([]);
const loading = ref<boolean>(false);
const rangeDate = ref<string[] | null>(null);
const objNews = ref<{
  name: string;
  is_active: boolean;
  clothing_size: string | null;
  category: string[];
  shoe_size: string | null;
  published_at: string | null;
  expired_at: string | null;
  city: string[];
  blocks: Block[];
}>({
  name: '',
  clothing_size: null,
  category: ['Все'],
  shoe_size: null,
  published_at: null,
  expired_at: null,
  is_active: false,
  city: ['Все'],
  blocks: [{ file: null, text: '', resolution: null }],
});
const shop = ref<{ name: string; instagram: string; whatsapp: string; is_active: boolean; opening_hours: string; description: string; city: string | null; image?: string; address: string; two_gis_address: string }>({
  name: '',
  instagram: '',
  whatsapp: '',
  description: '',
  opening_hours: '',
  is_active: false,
  city: null,
  image: '',
  address: '',
  two_gis_address: '',
});
const history = ref<{ name: string; type: string | null; is_active: boolean; description: string; city: string | null; actual: string | null; image?: string; video?: string; cover?: string }>({
  name: '',
  description: '',
  type: null,
  city: null,
  is_active: false,
  image: '',
  video: '',
  actual: null,
  cover: '',
});
const banner = ref<{ name: string; type: string | null; is_active: boolean; subtitle: string; city: string | null; image: any; video?: string }>({
  name: '',
  subtitle: '',
  type: null,
  city: null,
  is_active: false,
  image: '',
  video: '',
});
// const genres = ref<Api.Music.Genre[]>([]);
const cities = ref<Api.City[]>([]);
const categories = ref<Api.Category[]>([]);
const actuals = ref<Api.Actuals[]>([]);
// const entertainmentTypes = ref<Api.Dict[]>([]);
const bannersTypes = ref([
  {label: 'Фото', value: 'image'},
  {label: 'Видео', value: 'video'},
]);

const shoe_sizes = ref([
  {label: 'Все', value: null},
  {label: '39', value: 39},
  {label: '40', value: 40},
  {label: '41', value: 41},
  {label: '42', value: 42},
  {label: '43', value: 43},
  {label: '44', value: 44},
  {label: '45', value: 45},
  {label: '46', value: 46},
]);

const clothing_sizes = ref([
  {label: 'Все', value: null},
  {label: '46', value: 46},
  {label: '48', value: 48},
  {label: '50', value: 50},
  {label: '52', value: 52},
  {label: '54', value: 54},
  {label: '56', value: 56},
  {label: '58', value: 58},
  {label: '60', value: 60},
  {label: '62', value: 62},
  {label: '64', value: 64},
]);
const which = computed(() => String(route.params.tab) as keyof typeof AdminEnums.ContentItems);
const id = computed<number | 'new'>(() => (route.params.id === 'new' ? 'new' : Number(route.params.id)));
const brItems: Types.Crumb[] = [
  {title: t(`admin.content.${which.value}`), to: {name: 'content', query: {tab: which.value}}, disabled: false},
  {
    title: (id.value === 'new' ? 'Добавить ' : 'Редактировать ') + t(`admin.content.${which.value}`),
    to: {...route},
    disabled: false
  },
];


const onActualChange = (value: any) => {
  showCategoryInput.value = value === '+ добавить категорию';
};

function isImage(file: string, index:number): boolean {
  objNews.value.blocks[index].resolution = '';
  const cleanFile = file.split('?')[0];
  const res = cleanFile.startsWith('data:image') || /\.(jpe?g|png|gif|webp|bmp|svg)$/i.test(cleanFile);
  return res;
}

const isVideo = (file: string, index: number) => {
  // Note: Video resolution detection moved to onFileChange handler
  const cleanFile = file.split('?')[0];
  const res = cleanFile.startsWith('data:video') || /\.(mp4|webm|ogg|mov|avi|mkv|quicktime)$/i.test(cleanFile);
  return res;
}

function getVideoOrientationFromBase64(base64: string): Promise<"portrait" | "album" | "square"> {
  return new Promise((resolve, reject) => {
    const videoEl = document.createElement("video");
    videoEl.preload = "metadata";

    videoEl.onloadedmetadata = () => {
      const orientation = videoEl.videoWidth > videoEl.videoHeight ? "album" : (videoEl.videoHeight > videoEl.videoWidth ? "portrait" : "square");
      resolve(orientation);
      URL.revokeObjectURL(videoEl.src);
    };

    videoEl.onerror = (err) => {
      console.error('getVideoOrientationFromBase64 error', err);
      reject(err);
    };
    videoEl.src = base64;
  });
}

// Функции для периода новости
const formatDisplayDate = (dateStr: string | null): string => {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  return date.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short', year: 'numeric' });
};

const setNewsPeriod = (days: number) => {
  const today = new Date();
  const endDate = new Date(today);
  endDate.setDate(endDate.getDate() + days);
  
  objNews.value.published_at = today.toISOString().split('T')[0];
  objNews.value.expired_at = endDate.toISOString().split('T')[0];
  showPeriodMenu.value = false;
};

const clearNewsPeriod = () => {
  objNews.value.published_at = null;
  objNews.value.expired_at = null;
};

// Мультиселект для городов
const citiesForSelection = computed(() => {
  return cities.value.filter((c: any) => c.name && c.name !== 'Все');
});

const isCitySelected = (cityName: string): boolean => {
  // Если выбрано "Все", индивидуальные города не подсвечиваются
  if (objNews.value.city.includes('Все')) return false;
  return objNews.value.city.includes(cityName);
};

const toggleCity = (cityName: string) => {
  if (cityName === 'Все') {
    // Если выбираем "Все", очищаем и добавляем только "Все"
    objNews.value.city = ['Все'];
    return;
  }
  
  // Убираем "Все" если есть
  objNews.value.city = objNews.value.city.filter(c => c !== 'Все');
  
  const index = objNews.value.city.indexOf(cityName);
  if (index === -1) {
    objNews.value.city.push(cityName);
  } else {
    objNews.value.city.splice(index, 1);
  }
  
  // Если ничего не выбрано, выбираем "Все"
  if (objNews.value.city.length === 0) {
    objNews.value.city = ['Все'];
  }
};

// Мультиселект для категорий
const categoriesForSelection = computed(() => {
  return categories.value.filter((c: any) => c.name && c.name !== 'Все');
});

const isCategorySelected = (categoryName: string): boolean => {
  // Если выбрано "Все", индивидуальные категории не подсвечиваются
  if (objNews.value.category.includes('Все')) return false;
  return objNews.value.category.includes(categoryName);
};

const toggleCategory = (categoryName: string) => {
  if (categoryName === 'Все') {
    objNews.value.category = ['Все'];
    return;
  }
  
  objNews.value.category = objNews.value.category.filter(c => c !== 'Все');
  
  const index = objNews.value.category.indexOf(categoryName);
  if (index === -1) {
    objNews.value.category.push(categoryName);
  } else {
    objNews.value.category.splice(index, 1);
  }
  
  if (objNews.value.category.length === 0) {
    objNews.value.category = ['Все'];
  }
};

const addCategory = async () => {
  if (!newCategory.value.trim()) return;
  const newCat = {id: Date.now(), name: newCategory.value, is_system: false};
  actuals.value.splice(actuals.value.length - 1, 0, newCat);
  history.value.actual = newCat.name;
  newCategory.value = '';
  showCategoryInput.value = false;
  // Фильтруем только категории для сохранения (без "Все" и "+ добавить категорию")
  const trimmed = actuals.value.filter((a: any) => a.name !== 'Все' && a.name !== '+ добавить категорию');
  await api.actuals.add(trimmed)
};

const deleteItem = async (item: any) => {
  if (item.name === '+ добавить категорию') return;
  if (item.name === 'Все') return;
  // Системные группы теперь определяются по полю is_system из БД
  if (item.is_system) return;

  const index = actuals.value.findIndex(i => i.id === item.id);
  if (index !== -1) actuals.value.splice(index, 1);
  if (history.value.actual === item.id) history.value.actual = null;
  // Фильтруем только несистемные группы для сохранения
  const trimmed = actuals.value.filter((a: any) => a.name !== 'Все' && a.name !== '+ добавить категорию');
  await api.actuals.add(trimmed);
};

const logFileSize = (file: File | string, message: string = '') => {
  if (typeof file === 'string') {
    const size = getBase64Size(file);
    return formatFileSize(size);
  } else {
    const sizeInMB = (file.size / (1024 * 1024)).toFixed(2);
    return sizeInMB;
  }
};

const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

const getBase64Size = (base64String: string): number => {
  const base64 = base64String.includes(';base64,') ? base64String.split(';base64,')[1] : base64String;
  return (base64.length * 3) / 4 - (base64.endsWith('==') ? 2 : base64.endsWith('=') ? 1 : 0);
};

const compressionInfo = ref<{
  originalSize: string;
  compressedSize: string;
  reductionPercent: number;
} | null>(null);

const compressedFiles = ref<Record<string, File | null>>({});

function compressWithCompressor(file: File, opts: { quality?: number; maxWidth?: number; maxHeight?: number } = {}): Promise<File> {
  const { quality = 0.85, maxWidth = 1200, maxHeight = 1200 } = opts;
  return new Promise((resolve, reject) => {
    try {
      new Compressor(file, {
        quality,
        maxWidth,
        maxHeight,
        convertSize: 1000000,
        success(result: Blob) {
          const outType = result.type || 'image/jpeg';
          const ext = outType.includes('webp') ? '.webp' : outType.includes('png') ? '.png' : '.jpg';
          const outName = file.name.replace(/\.\w+$/, '') + ext;
          const outFile = new File([result], outName, { type: outType });
          resolve(outFile);
        },
        error(err) {
          console.error('compressWithCompressor error for', file.name, err);
          reject(err);
        },
      });
    } catch (e) {
      console.error('compressWithCompressor exception', e);
      reject(e);
    }
  });
}

function base64ToFile(base64: string, filename: string): File | null {
  try {
    const arr = base64.split(',');
    const mime = arr[0].match(/:(.*?);/)?.[1] || 'application/octet-stream';
    const bstr = atob(arr[1]);
    let n = bstr.length;
    const u8arr = new Uint8Array(n);
    while (n--) {
      u8arr[n] = bstr.charCodeAt(n);
    }
    return new File([u8arr], filename, { type: mime });
  } catch (error) {
    console.error('base64ToFile :', error);
    return null;
  }
}

function convertToBase64(file: File | Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => {
      if (typeof reader.result === 'string') {
        resolve(reader.result);
      } else {
        reject(new Error('FileReader нәтижесі жол емес'));
      }
    };
    reader.onerror = (err) => reject(err);
  });
}

const handlePhotoUpload = async (fileOrBase64: File | string, keyHint?: string) => {

  try {
    if (typeof fileOrBase64 === 'string') {
      if (fileOrBase64.startsWith('data:image/')) {
        const inferredExt = (fileOrBase64.match(/data:image\/(.*?);/) || [null, 'png'])[1] || 'png';
        const filename = `img_from_base64.${inferredExt}`;

        const originalFile = base64ToFile(fileOrBase64, filename);
        if (!originalFile) {
          showToaster('error', 'Не удалось обработать изображение');
          return;
        }

        try {
          const compressed = await compressWithCompressor(originalFile, {
            quality: 0.99,
            maxWidth: 1600,
            maxHeight: 1600
          });

          const previewBase64 = await convertToBase64(compressed);

          if (which.value === 'banners') {
            banner.value.image = previewBase64;
            compressedFiles.value['banner_image'] = compressed;
          } else if (which.value === 'shops') {
            shop.value.image = previewBase64;
            compressedFiles.value['shop_image'] = compressed;
          } else if (which.value === 'histories') {
            history.value.image = previewBase64;
            compressedFiles.value['history_image'] = compressed;
          } else if (keyHint) {
            compressedFiles.value[keyHint] = compressed;
          }

          compressionInfo.value = {
            originalSize: formatFileSize(originalFile.size),
            compressedSize: formatFileSize(compressed.size),
            reductionPercent: Math.round(((originalFile.size - compressed.size) / originalFile.size) * 100),
          };

          showToaster('success', `Изображение сжато: ${compressionInfo.value.reductionPercent}%`);
          return;
        } catch (compressErr) {
          console.error('handlePhotoUpload: compression failed for converted base64 -> File', compressErr);
          if (which.value === 'banners') banner.value.image = fileOrBase64;
          else if (which.value === 'shops') shop.value.image = fileOrBase64;
          else if (which.value === 'histories') history.value.image = fileOrBase64;
          showToaster('warning', 'Не удалось сжать изображение, сохранён preview');
          return;
        }
      } else if (/^https?:\/\//.test(fileOrBase64)) {
        if (which.value === 'banners') banner.value.image = fileOrBase64;
        else if (which.value === 'shops') shop.value.image = fileOrBase64;
        else if (which.value === 'histories') history.value.image = fileOrBase64;
        return;
      } else {
        console.warn('handlePhotoUpload: string received but not base64 or URL. Storing as is.');
        if (which.value === 'banners') banner.value.image = fileOrBase64;
        else if (which.value === 'shops') shop.value.image = fileOrBase64;
        else if (which.value === 'histories') history.value.image = fileOrBase64;
        return;
      }
    }

    if (fileOrBase64 instanceof File) {
      const compressed = await compressWithCompressor(fileOrBase64, {
        quality: 0.99,
        maxWidth: 1600,
        maxHeight: 1600
      });

      const previewBase64 = await convertToBase64(compressed);

      if (which.value === 'banners') {
        banner.value.image = previewBase64;
        compressedFiles.value['banner_image'] = compressed;
      } else if (which.value === 'shops') {
        shop.value.image = previewBase64;
        compressedFiles.value['shop_image'] = compressed;
      } else if (which.value === 'histories') {
        history.value.image = previewBase64;
        compressedFiles.value['history_image'] = compressed;
      } else if (keyHint) {
        compressedFiles.value[keyHint] = compressed;
      }

      compressionInfo.value = {
        originalSize: formatFileSize(fileOrBase64.size),
        compressedSize: formatFileSize(compressed.size),
        reductionPercent: Math.round(((fileOrBase64.size - compressed.size) / fileOrBase64.size) * 100),
      };

      showToaster('success', `Изображение сжато: ${compressionInfo.value.reductionPercent}%`);
      return;
    }

  } catch (err) {
    console.error('handlePhotoUpload caught error:', err);
    showToaster('error', 'Ошибка при обработке изображения');
  }
};

const handleVideoUpload = async (file: File, target: 'banner' | 'history') => {
  try {
    if (!file.type.startsWith('video/')) {
      showToaster('error', 'Бұл видео файл емес');
      return;
    }

    // Видео файлының өлшемін тексеру (30MB шек)
    const videoSizeMB = Number((file.size / (1024 * 1024)).toFixed(2));
    if (file.size > 30 * 1024 * 1024) {
      showToaster('error', 'Видео 30MB-тан үлкен болмауы керек');
      console.warn('handleVideoUpload rejected due to size:', formatFileSize(file.size));
      return;
    }

    const allowedFormats = ['mp4', 'webm', 'ogg', 'mov', 'avi', 'mkv'];
    const fileExtension = file.name.split('.').pop()?.toLowerCase();
    if (!fileExtension || !allowedFormats.includes(fileExtension)) {
      showToaster('error', 'Рұқсат етілмеген видео форматы. MP4, WebM, OGG, MOV, AVI, MKV форматтары рұқсат етілген');
      return;
    }

    console.log('Видео файл тексерілді:', {
      name: file.name,
      size: formatFileSize(file.size),
      type: file.type,
      extension: fileExtension
    });

    const base64 = await convertToBase64(file);

    if (target === 'banner') {
      banner.value.video = base64;
      compressedFiles.value['banner_video'] = file;
    } else {
      history.value.video = base64;
      compressedFiles.value['history_video'] = file;
    }

    showToaster('success', `Видео дайын: ${formatFileSize(file.size)}`);

  } catch (err) {
    console.error('handleVideoUpload қатесі:', err);
    showToaster('error', 'Видео өңдеу кезінде қате орын алды');
  }
};

async function onFileChange(event: Event, index: number) {
  const target = event.target as HTMLInputElement;
  const file = target.files?.[0];
  if (!file) {
    console.warn('onFileChange: no file selected');
    return;
  }

  try {
    if (file.type.startsWith('image/')) {
      const compressed = await compressWithCompressor(file, {
        quality: 0.99,
        maxWidth: 1600,
        maxHeight: 1600
      });
      compressedFiles.value[`block_${index}`] = compressed;
      objNews.value.blocks[index].file = await convertToBase64(compressed); // preview
      objNews.value.blocks[index].resolution = '';
    } else if (file.type.startsWith('video/')) {
      if (file.size > 30 * 1024 * 1024) {
        showToaster('error', 'Видео 30MB-тан үлкен болмауы керек');
        console.warn('onFileChange video rejected for size', formatFileSize(file.size));
        return;
      }
      compressedFiles.value[`block_${index}_video`] = file;
      objNews.value.blocks[index].file = await convertToBase64(file);
      objNews.value.blocks[index].resolution = '';
    }
  } catch (err) {
    console.error('onFileChange error', err);
    objNews.value.blocks[index].file = await convertToBase64(file);
    objNews.value.blocks[index].resolution = '';
  }
}

// Обработка загрузки обложки новости (получает base64 от file-input)
const onCoverUpload = (base64: string) => {
  objNews.value.blocks[0].file = base64;
};

async function onCoverImgChange(event: Event) {
  const target = event.target as HTMLInputElement;
  const file = target.files?.[0];
  if (!file) {
    console.warn('onCoverImgChange: no file');
    return;
  }
  try {
    if (file.type.startsWith('image/')) {
      const compressed = await compressWithCompressor(file, {
        quality: 0.99,
        maxWidth: 1600,
        maxHeight: 1600
      });
      compressedFiles.value['history_cover'] = compressed;
      history.value.cover = await convertToBase64(compressed);
      showToaster('success', 'Обложка сжата и готова к загрузке');
    } else {
      history.value.cover = await convertToBase64(file);
      compressedFiles.value['history_cover'] = file;
      showToaster('success', 'Обложка загружена');
    }
  } catch (err) {
    console.error('onCoverImgChange error', err);
    history.value.cover = await convertToBase64(file);
    showToaster('success', 'Обложка загружена (без сжатия)');
  }
}

const save = useDebounceFn(
  async () => {
    await form.value.validate().then(async (v: Types.VFormValidation) => {
      if (v.valid) {
        loading.value = true;
        const formData = new FormData();
        const payload: Record<string, any> = {};

        try {
          if (which.value === 'news') {
            payload.name = objNews.value.name;
            formData.append('name', objNews.value.name);

            // City и Category теперь массивы
            payload.city = objNews.value.city;
            payload.category = objNews.value.category;

            objNews.value.expired_at = objNews.value.expired_at;

            formData.append('published_at', formatToYYYYMMDD(objNews.value.published_at));
            formData.append('expired_at', formatToYYYYMMDD(objNews.value.expired_at));

            payload.published_at = formatToYYYYMMDD(objNews.value.published_at);
            payload.expired_at = formatToYYYYMMDD(objNews.value.expired_at);

            const shoeValue = objNews.value.shoe_size === 'Все' ? null : objNews.value.shoe_size;
            formData.append('shoe_size', shoeValue !== null ? shoeValue.toString() : '');
            payload.shoe_size = shoeValue !== null ? shoeValue.toString() : null;

            const clothValue = objNews.value.clothing_size === 'Все' ? null : objNews.value.clothing_size;
            formData.append('clothing_size', clothValue !== null ? clothValue.toString() : '');
            payload.clothing_size = clothValue !== null ? clothValue.toString() : null;

            formData.append('is_active', objNews.value.is_active ? '1' : '0');
            payload.is_active = objNews.value.is_active ? 1 : 0;
            payload.blocks = objNews.value.blocks;
          }

          if (which.value === 'shops') {
            if (id.value !== 'new') {
              if (shop.value.image) formData.append('file_path', shop.value.image);
            } else {
              if (typeof shop.value.image === 'string' && shop.value.image.startsWith('data:image/')) {
                const file = base64ToFile(shop.value.image, 'image.png');
                if (file) formData.append('file', file);
              } else if (shop.value.image && (shop.value.image as any) instanceof File) {
                formData.append('file', shop.value.image as any);
              }
            }

            formData.append('name', shop.value.name);
            formData.append('address', shop.value.address);
            formData.append('two_gis_address', shop.value.two_gis_address);
            formData.append('instagram', shop.value.instagram);
            formData.append('whatsapp', shop.value.whatsapp);

            const cityValue = shop.value.city === 'Все' ? 'Все' : shop.value.city;
            if (cityValue) formData.append('city', cityValue);

            formData.append('type', 'image');
            formData.append('description', String(shop.value.description));
            formData.append('opening_hours', String(shop.value.opening_hours));
            formData.append('is_active', shop.value.is_active ? '1' : '0');

            payload.city = cityValue;
            payload.is_active = shop.value.is_active ? 1 : 0;
            payload.opening_hours = String(shop.value.opening_hours);
            payload.name = shop.value.name;
            payload.file = shop.value.image;
            payload.address = shop.value.address;
            payload.two_gis_address = shop.value.two_gis_address;
            payload.instagram = shop.value.instagram;
            payload.whatsapp = shop.value.whatsapp;
          }

          if (which.value === 'histories') {
            console.log('Stories сақтау басталды:', history.value);

            if (!history.value.name) {
              showToaster('error', 'Атауы міндетті');
              loading.value = false;
              return;
            }

            if (!history.value.city) {
              showToaster('error', 'Қала міндетті');
              loading.value = false;
              return;
            }

            if (!history.value.type) {
              showToaster('error', 'Тип міндетті');
              loading.value = false;
              return;
            }

            if (!history.value.actual) {
              showToaster('error', 'Актуалды топ міндетті');
              loading.value = false;
              return;
            }

            if (history.value.type === 'image' && !history.value.image) {
              showToaster('error', 'Сурет міндетті');
              loading.value = false;
              return;
            }

            if (history.value.type === 'video' && !history.value.video) {
              showToaster('error', 'Видео міндетті');
              loading.value = false;
              return;
            }

            formData.append('name', history.value.name);

            const cityValue = history.value.city === 'Все' ? 'Все' : history.value.city;
            formData.append('city', cityValue);

            const actualValue = history.value.actual === 'Все' ? "Все" : history.value.actual;
            formData.append('actual_group', actualValue);

            formData.append('description', String(history.value.description || ''));
            formData.append('is_active', history.value.is_active ? '1' : '0');
            formData.append('type', String(history.value.type));

            if (history.value.type === 'image') {
              if (typeof history.value.image === 'string' && history.value.image.startsWith('data:image/')) {
                const file = base64ToFile(history.value.image, 'image.jpg');
                if (file) formData.append('file', file);
              } else if (compressedFiles.value['history_image']) {
                formData.append('file', compressedFiles.value['history_image']);
              } else if (history.value.image && (history.value.image as any) instanceof File) {
                formData.append('file', history.value.image as any);
              }

              if (history.value.cover) {
                if (typeof history.value.cover === 'string' && history.value.cover.startsWith('data:image/')) {
                  const coverFile = base64ToFile(history.value.cover, 'cover.jpg');
                  if (coverFile) formData.append('cover', coverFile);
                } else if (compressedFiles.value['history_cover']) {
                  formData.append('cover', compressedFiles.value['history_cover']);
                } else if ((history.value.cover as any) instanceof File) {
                  formData.append('cover', history.value.cover as any);
                }
              }
            }
            else if (history.value.type === 'video') {
              if (typeof history.value.video === 'string' && history.value.video.startsWith('data:video/')) {
                const file = base64ToFile(history.value.video, 'video.mp4');
                if (file) formData.append('file', file);
              } else if (compressedFiles.value['history_video']) {
                formData.append('file', compressedFiles.value['history_video']);
              } else if (history.value.video && (history.value.video as any) instanceof File) {
                formData.append('file', history.value.video as any);
              }

              if (history.value.cover) {
                if (typeof history.value.cover === 'string' && history.value.cover.startsWith('data:image/')) {
                  const coverFile = base64ToFile(history.value.cover, 'cover.jpg');
                  if (coverFile) formData.append('cover', coverFile);
                } else if (compressedFiles.value['history_cover']) {
                  formData.append('cover', compressedFiles.value['history_cover']);
                } else if ((history.value.cover as any) instanceof File) {
                  formData.append('cover', history.value.cover as any);
                }
              }
            }

            for (let [key, value] of formData.entries()) {
              console.log(key, value instanceof File ? `File: ${value.name}, ${value.size} bytes` : value);
            }

            payload.name = history.value.name;
            payload.city = cityValue;
            payload.is_active = history.value.is_active ? 1 : 0;
            payload.description = String(history.value.description);
            payload.actual_group = actualValue;
            payload.type = String(history.value.type);

            if (history.value.type === 'image') {
              payload.file = history.value.image;
              payload.cover = history.value.cover;
            } else if (history.value.type === 'video') {
              payload.file = history.value.video;
              payload.cover = history.value.cover;
            }
          }

          if (which.value === 'banners') {
            if (id.value !== 'new') {
              if (banner.value.image) formData.append('file_path', banner.value.image);
            } else {
              if (banner.value.type === 'image') {
                if (typeof banner.value.image === 'string' && banner.value.image.startsWith('data:image/')) {
                  const file = base64ToFile(banner.value.image, 'image.png');
                  if (file) formData.append('file', file);
                } else if (banner.value.image && (banner.value.image as any) instanceof File) {
                  formData.append('file', banner.value.image as any);
                }
              }
              if (banner.value.type === 'video') {
                if (typeof banner.value.video === 'string' && banner.value.video.startsWith('data:video/')) {
                  const file = base64ToFile(banner.value.video, 'video.mp4');
                  if (file) formData.append('file', file);
                } else if (banner.value.video && (banner.value.video as any) instanceof File) {
                  formData.append('file', banner.value.video as any);
                }
              }
            }

            formData.append('name', banner.value.name);
            formData.append('subtitle', banner.value.subtitle);
            const cityValue = banner.value.city === 'Все' ? 'Все' : banner.value.city;
            if (cityValue) formData.append('city', cityValue);
            formData.append('type', String(banner.value.type));
            formData.append('is_active', banner.value.is_active ? '1' : '0');

            payload.name = banner.value.name;
            payload.subtitle = banner.value.subtitle;
            payload.city = cityValue;
            payload.type = String(banner.value.type);
            payload.is_active = banner.value.is_active ? 1 : 0;
            payload.file = banner.value.image;
            if (banner.value.type === 'video') {
              payload.file = banner.value.video;
            }
          }


          let response;
          if (id.value === 'new') {
            if (which.value === 'news' || which.value === 'histories') {
              response = await (api[which.value] as any).add(payload);
            } else {
              response = await (api[which.value] as any).add(formData);
            }
          } else {
            if (which.value === 'news' || which.value === 'histories' || which.value === 'shops' || which.value === 'banners') {
              response = await (api[which.value] as any).update(id.value, payload);
            } else {
              response = await (api[which.value] as any).update(id.value, formData);
            }
          }

          if (response) {
            await router.push('/content');
            await get();
            if (response.message) showToaster('success', String(response.message));
          }

        } catch (err: any) {
          console.error('API қатесі:', err);

          if (err.response?.data) {
            console.error('Қате деректері:', err.response.data);
            if (err.response.data.errors) {
              const errorMessages = Object.values(err.response.data.errors).flat();
              showToaster('error', errorMessages.join(', '));
            } else if (err.response.data.message) {
              showToaster('error', err.response.data.message);
            }
          } else {
            showToaster('error', 'Сервер қатесі орын алды');
          }
        } finally {
          loading.value = false;
        }
      }
    });
  },
  500,
  {maxWait: 3000},
);

const getEditorHTML = () => {
  const editor = document.querySelector('.ql-editor');
  if (!editor) return '';
  let htmlContent = editor.innerHTML;
  htmlContent = htmlContent.replace(/class="ql-size-(\w+)"/g, (match, size) => {
    let fontSize;
    switch (size) {
      case 'small': fontSize = '12px'; break;
      case 'large': fontSize = '18px'; break;
      case 'huge': fontSize = '24px'; break;
      default: fontSize = '16px';
    }
    return `style="font-size: ${fontSize};"`;
  });
  return htmlContent;
};

const setEditorHTML = (description: string) => {
  if (!description) return '';
  const contentWithClasses = description.replace(/style="font-size:\s*(\d+)px;?"/g, (match: string, size: string) => {
    let quillClass;
    switch (size) {
      case '12': quillClass = 'ql-size-small'; break;
      case '18': quillClass = 'ql-size-large'; break;
      case '24': quillClass = 'ql-size-huge'; break;
      default: quillClass = '';
    }
    return quillClass ? `class="${quillClass}"` : '';
  });
  const editor = document.querySelector('.ql-editor');
  if (editor) editor.innerHTML = contentWithClasses;
};

const get = async () => {
  try {
    if (id.value !== 'new') {
      const apiResponse = await (api[which.value] as any).get(id.value);
      const response: any = apiResponse?.data || apiResponse;
      switch (which.value) {
        case 'news': {
          objNews.value.blocks = [];
          if (response?.blocks && Array.isArray(response.blocks)) {
            response.blocks.forEach((element: any, index: number) => {
              if (index === 0) {
                // Первый блок - обложка с описанием (оба поля)
                objNews.value.blocks.push({
                  file: element.media_path ? fileUrlValidator(element.media_path) : null,
                  text: element.text || '',
                  resolution: element.resolution || null,
                });
              } else {
                // Остальные блоки - либо медиа, либо текст
                const hasMedia = element.media_path && element.media_path.trim() !== '';
                
                if (hasMedia) {
                  objNews.value.blocks.push({
                    file: fileUrlValidator(element.media_path),
                    resolution: element.resolution || null,
                  });
                } else {
                  objNews.value.blocks.push({
                    text: element.text || '',
                    resolution: element.resolution || null,
                  });
                }
              }
            });
          }
          // Если нет блоков, добавляем пустой первый блок (для обложки и описания)
          if (objNews.value.blocks.length === 0) {
            objNews.value.blocks.push({ file: null, text: '', resolution: null });
          }

          objNews.value.name = response.name || '';
          // Обработка города (может быть строкой или массивом)
          if (Array.isArray(response.city)) {
            objNews.value.city = response.city.length > 0 ? response.city : ['Все'];
          } else {
            objNews.value.city = response.city ? [response.city] : ['Все'];
          }
          // Обработка категории (может быть строкой или массивом)
          if (Array.isArray(response.category)) {
            objNews.value.category = response.category.length > 0 ? response.category : ['Все'];
          } else {
            objNews.value.category = response.category && response.category !== 'null' ? [response.category] : ['Все'];
          }
          objNews.value.is_active = !!response.is_active;
          objNews.value.shoe_size = response.shoe_size === 'null' ? null : response.shoe_size;
          objNews.value.clothing_size = response.clothing_size === 'null' ? null : response.clothing_size;
          objNews.value.published_at = response.published_at ? response.published_at.split('T')[0] : null;
          objNews.value.expired_at = response.expired_at ? response.expired_at.split('T')[0] : null;
          return;
        }
        case 'shops': {
          shop.value.name = response.name;
          shop.value.description = response.description;
          shop.value.whatsapp = response.whatsapp;
          shop.value.instagram = response.instagram;
          shop.value.city = response.city || 'Все';
          shop.value.is_active = !!response.is_active;
          shop.value.opening_hours = response.opening_hours;
          shop.value.image = fileUrlValidator(response.file_path);
          shop.value.address = response.address;
          shop.value.two_gis_address = response.two_gis_address;
          return;
        }
        case 'histories': {
          history.value.name = response.name;
          history.value.description = response.description;
          history.value.city = response.city || 'Все';

          history.value.type = response.type;
          history.value.is_active = !!response.is_active;
          history.value.actual = response.actual_group === 'null' ? 'Все' : response.actual_group;

          if (response.cover_path)
            history.value.cover = fileUrlValidator(response.cover_path);

          history.value.image = fileUrlValidator(response.file_path);
          history.value.video = fileUrlValidator(response.file_path);
          return;
        }
        case 'banners': {
          banner.value.name = response.name;
          banner.value.subtitle = response.subtitle;
          banner.value.city = response.city || 'Все';
          banner.value.type = response.type;
          banner.value.is_active = !!response.is_active;
          banner.value.image = fileUrlValidator(response.file_path);
          banner.value.video = fileUrlValidator(response.file_path);
          return;
        }
      }
    }
  } catch (err) {
    console.log(err);
  }
};

const getData = async () => {
  try {
    if (which.value === 'news') {
      try {
        const response = await api.cities.getAll();
        const citiesData = Array.isArray(response) ? response : (response?.data || []);
        if (citiesData.length) cities.value = [{name: 'Все', value: null} as any, ...citiesData];

        const cats = await api.categories.getAll();
        const catsData = Array.isArray(cats) ? cats : (cats?.data || []);
        if (catsData.length) categories.value = [{id: null, name: 'Все'} as any, ...catsData];
      } catch (err) {
        console.log(err);
      }
    }
    if (which.value === 'shops') {
      try {
        const response = await api.cities.getAll();
        const citiesData = Array.isArray(response) ? response : (response?.data || []);
        if (citiesData.length) cities.value = [{name: 'Все'} as any, ...citiesData];
      } catch (err) {
        console.log(err);
      }
    }
    if (which.value === 'histories') {
      try {
        const response = await api.cities.getAll();
        const citiesData = Array.isArray(response) ? response : (response?.data || []);
        if (citiesData.length) cities.value = [{name: 'Все'} as any, ...citiesData];
        
        const cats = await api.actuals.getAll();
        const actualsData = Array.isArray(cats) ? cats : (cats?.data || []);
        // Теперь системные группы приходят из БД, не нужен хардкод
        if (actualsData.length) actuals.value = [{name: 'Все'} as any, ...actualsData, {
          id: "new",
          name: "+ добавить категорию"
        } as any];
      } catch (err) {
        console.log(err);
      }
    }
    if (which.value === 'banners') {
      try {
        const response = await api.cities.getAll();
        const citiesData = Array.isArray(response) ? response : (response?.data || []);
        if (citiesData.length) cities.value = [{name: 'Все'} as any, ...citiesData];
      } catch (err) {
        console.log(err);
      }
    }
  } catch (err) {
    console.log(err);
  }
};

function addTextBlock() { objNews.value.blocks.push({ text: '', resolution: null }); }
function addImageBlock() { objNews.value.blocks.push({ file: null, resolution: null }); }
function removeBlock(index: number) { if (index >= 0 && index < objNews.value.blocks.length) { objNews.value.blocks.splice(index, 1);} }

// Drag & Drop для контент-блоков
const draggingBlockIndex = ref<number | null>(null);
const isDraggingBlock = ref(false);
let lastBlockSwapTime = 0;
const BLOCK_SWAP_THROTTLE = 150;

const onBlockDragStart = (index: number, event: DragEvent) => {
  // index здесь относительно slice(1), поэтому реальный индекс = index + 1
  draggingBlockIndex.value = index;
  isDraggingBlock.value = true;
  lastBlockSwapTime = 0;
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

const onBlockDragOver = (index: number, event: DragEvent) => {
  event.preventDefault();
  if (event.dataTransfer) {
    event.dataTransfer.dropEffect = 'move';
  }
  const sourceIndex = draggingBlockIndex.value;
  if (sourceIndex === null || sourceIndex === index) return;
  
  const now = Date.now();
  if (now - lastBlockSwapTime < BLOCK_SWAP_THROTTLE) return;
  lastBlockSwapTime = now;
  
  // Перестроение (индексы относительно slice(1), поэтому +1 для реального массива)
  const realSourceIndex = sourceIndex + 1;
  const realTargetIndex = index + 1;
  
  const items = [...objNews.value.blocks];
  const [removed] = items.splice(realSourceIndex, 1);
  items.splice(realTargetIndex, 0, removed);
  objNews.value.blocks = items;
  draggingBlockIndex.value = index;
};

const onBlockDrop = (event: DragEvent) => {
  event.preventDefault();
};

const onBlockDragEnd = (event: DragEvent) => {
  if (event.target instanceof HTMLElement) {
    event.target.style.opacity = '';
  }
  draggingBlockIndex.value = null;
  isDraggingBlock.value = false;
  lastBlockSwapTime = 0;
};

const onDelete = async () => {
  try {
    const response = await api[layoutStore.contentTab].delete(id.value as number);
    if (response.message) showToaster('success', "Успешно удалено");
    await router.push('/content');
  } catch (err) {
    console.error('onDelete error', err);
  }
};

useHead({
  title: () => `${t('admin.nav.content')} - ${(id.value === 'new' ? 'Добавить ' : 'Редактировать ') + t(`admin.content.${which.value}`)}`,
});

onBeforeMount(() => {
  const tab = String(route.params.tab) as AdminEnums.ContentItems;
  if (tab && tab in AdminEnums.ContentItems) {
    if (layoutStore.contentTab !== tab) layoutStore.contentTab = tab;
  } else router.push({name: 'content'});
});

onMounted(async () => {
  // Баннеры теперь редактируются inline на основной странице
  if (which.value === 'banners') {
    navigateTo('/content?tab=banners');
    return;
  }
  
  await getData();
  await get();
});
</script>

<style scoped>
/* ===== CONTENT-EDIT BEM STYLES ===== */
.content-edit {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.content-edit__header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 6px;
  flex-wrap: wrap;
  gap: 0.75rem;
}

@media (max-width: 599px) {
  .content-edit__header {
    flex-direction: column;
    align-items: stretch;
  }
}

.content-edit__breadcrumbs {
  color: var(--color-text-secondary);
}

:root.dark .content-edit__breadcrumbs {
  color: white;
}

.content-edit__actions {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

@media (max-width: 599px) {
  .content-edit__actions {
    width: 100%;
    justify-content: flex-end;
  }
}

.content-edit__delete-btn {
  background-color: #dc2626 !important;
  color: white !important;
}

.content-edit__delete-btn:hover {
  background-color: #b91c1c !important;
}

.content-edit__delete-btn .v-btn__content,
.content-edit__delete-btn .v-icon {
  color: white !important;
}

.content-edit__form {
  color: var(--color-text-primary);
}

:root.dark .content-edit__form {
  color: white;
}

.content-edit__section {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  min-height: auto;
}

@media (min-width: 960px) {
  .content-edit__section {
    flex-direction: row;
    gap: 1.5rem;
    min-height: 350px;
  }
}

.content-edit__sidebar {
  width: 100%;
}

@media (min-width: 960px) {
  .content-edit__sidebar {
    width: 30%;
    min-width: 250px;
    max-width: 350px;
  }
}

.content-edit__main {
  width: 100%;
}

@media (min-width: 960px) {
  .content-edit__main {
    flex: 1;
    width: auto;
  }
}

.content-edit__card {
  width: 100%;
}

.content-edit__card-title {
  margin-bottom: 0.5rem;
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.content-edit__fields {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
  gap: 0.25rem;
}

/* ===== TAILWIND OVERRIDES FOR MOBILE ===== */

/* Main content sections - responsive layout */
section.tw-flex.tw-min-h-\[350px\].tw-gap-6,
section.tw-flex.tw-min-h-\[500px\].tw-gap-6 {
  flex-direction: column;
  gap: 1rem;
  min-height: auto;
}

@media (min-width: 600px) {
  section.tw-flex.tw-min-h-\[350px\].tw-gap-6,
  section.tw-flex.tw-min-h-\[500px\].tw-gap-6 {
    gap: 1.25rem;
  }
}

@media (min-width: 960px) {
  section.tw-flex.tw-min-h-\[350px\].tw-gap-6,
  section.tw-flex.tw-min-h-\[500px\].tw-gap-6 {
    flex-direction: row;
    gap: 1.5rem;
    min-height: 350px;
  }
  
  section.tw-flex.tw-min-h-\[500px\].tw-gap-6 {
    min-height: 500px;
  }
}

/* Left column (image/video upload) */
.tw-w-1\/4 {
  width: 100%;
}

@media (min-width: 960px) {
  .tw-w-1\/4 {
    width: 30%;
    min-width: 250px;
    max-width: 350px;
  }
}

@media (min-width: 1280px) {
  .tw-w-1\/4 {
    width: 25%;
  }
}

/* Right column (form fields) */
.tw-w-3\/4 {
  width: 100%;
}

@media (min-width: 960px) {
  .tw-w-3\/4 {
    flex: 1;
    width: auto;
  }
}

/* Full width sections */
.tw-w-full {
  width: 100%;
}

/* Card forms */
.tw-h-fit.tw-w-full {
  height: fit-content;
  width: 100%;
}

/* Form inputs */
.tw-flex.tw-grow.tw-flex-col.tw-gap-1 {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
  gap: 0.5rem;
}

/* File input containers */
.tw-min-h-\[230px\] {
  min-height: 180px;
}

@media (min-width: 600px) {
  .tw-min-h-\[230px\] {
    min-height: 200px;
  }
}

@media (min-width: 960px) {
  .tw-min-h-\[230px\] {
    min-height: 230px;
  }
}

/* Block buttons at bottom */
.tw-mt-3.tw-flex.tw-justify-end.tw-gap-4 {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  margin-top: 1rem;
}

@media (min-width: 600px) {
  .tw-mt-3.tw-flex.tw-justify-end.tw-gap-4 {
    flex-direction: row;
    justify-content: flex-end;
    gap: 1rem;
    margin-top: 0.75rem;
  }
}

/* Labels */
.tw-text-sm {
  font-size: 0.8125rem;
}

@media (min-width: 600px) {
  .tw-text-sm {
    font-size: 0.875rem;
  }
}

/* Titles */
.tw-text-lg.tw-font-semibold {
  font-size: 1rem;
}

@media (min-width: 600px) {
  .tw-text-lg.tw-font-semibold {
    font-size: 1.125rem;
  }
}

/* Block cards spacing */
.tw-mt-4 {
  margin-top: 1rem;
}

/* Images and videos inside cards */
.tw-rounded-lg {
  border-radius: 0.5rem;
  max-width: 100%;
  height: auto;
}

/* Switch component */
.custom-switch {
  margin-right: 0.5rem;
}

.content-edit__switch-row {
  display: flex;
  align-items: center;
}

/* Taller sections */
.content-edit__section--tall {
  min-height: auto;
}

@media (min-width: 960px) {
  .content-edit__section--tall {
    min-height: 500px;
  }
}

/* ===== NEWS EDITOR REDESIGN ===== */
.news-editor {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1.5rem;
}

@media (min-width: 1024px) {
  .news-editor {
    grid-template-columns: 320px 1fr;
    gap: 2rem;
  }
}

/* Sidebar */
.news-editor__sidebar {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.news-editor__cover-card,
.news-editor__status-card {
  background: var(--color-bg-secondary, #fff);
  border-radius: 16px;
  padding: 1.25rem;
  border: 1px solid var(--color-border, #e5e7eb);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  transition: box-shadow 0.2s ease;
}

.news-editor__cover-card:hover,
.news-editor__status-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}

:root.dark .news-editor__cover-card,
:root.dark .news-editor__status-card {
  background: var(--color-bg-secondary, #1e1e1e);
  border-color: var(--color-border, #333);
}

.news-editor__cover-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}

.news-editor__cover-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
  font-size: 0.9375rem;
  color: var(--color-text-primary);
}

.news-editor__status-header {
  font-weight: 600;
  font-size: 0.9375rem;
  color: var(--color-text-primary);
  margin-bottom: 1rem;
}

.news-editor__cover-content {
  display: flex;
  flex-direction: column;
}

.news-editor__cover-dropzone {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 280px;
  padding: 1.5rem;
  border: 2px dashed var(--color-border, #d1d5db);
  border-radius: 12px;
  background: var(--color-bg-tertiary, #f9fafb);
  transition: all 0.2s ease;
  box-sizing: border-box;
}

.news-editor__cover-dropzone:hover {
  border-color: var(--color-primary, #C2E12E);
  background: rgba(194, 225, 46, 0.05);
}

:root.dark .news-editor__cover-dropzone {
  background: var(--color-bg-tertiary, #2a2a2a);
  border-color: var(--color-border, #444);
}

.news-editor__dropzone-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 1.5rem 1rem;
  text-align: center;
  gap: 0.5rem;
  width: 100%;
}

.news-editor__dropzone-content--compact {
  padding: 1rem;
}

.news-editor__dropzone-icon {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: rgba(194, 225, 46, 0.15);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 0.5rem;
}

.news-editor__dropzone-text {
  font-weight: 600;
  font-size: 0.9375rem;
  color: var(--color-text-primary);
  margin: 0;
}

.news-editor__dropzone-hint {
  font-size: 0.8125rem;
  color: var(--color-text-secondary, #6b7280);
  margin: 0;
}

.news-editor__dropzone-formats {
  font-size: 0.75rem;
  color: var(--color-text-tertiary, #9ca3af);
  margin-top: 0.5rem;
}

.news-editor__cover-preview {
  border-radius: 12px;
  overflow: hidden;
  background: var(--color-bg-tertiary, #f3f4f6);
}

.news-editor__cover-image {
  width: 100%;
  max-height: 320px;
  object-fit: cover;
  display: block;
}

/* Status card */
.news-editor__status-toggle {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.news-editor__status-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text-secondary, #6b7280);
  transition: color 0.2s ease;
}

.news-editor__status-label--active {
  color: #20C933;
}

/* Main content area */
.news-editor__main {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.news-editor__card {
  background: var(--color-bg-secondary, #fff);
  border-radius: 16px;
  padding: 1.5rem;
  border: 1px solid var(--color-border, #e5e7eb);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

:root.dark .news-editor__card {
  background: var(--color-bg-secondary, #1e1e1e);
  border-color: var(--color-border, #333);
}

.news-editor__card-header {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  margin-bottom: 1.25rem;
  padding-bottom: 0.75rem;
  border-bottom: 1px solid var(--color-border, #e5e7eb);
}

.news-editor__card-header h3 {
  font-size: 1.0625rem;
  font-weight: 600;
  margin: 0;
  color: var(--color-text-primary);
}

/* Form grid */
.news-editor__form-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1rem;
}

@media (min-width: 640px) {
  .news-editor__form-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

.news-editor__field--full {
  grid-column: 1 / -1;
}

.news-editor__label {
  display: block;
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--color-text-secondary, #6b7280);
  margin-bottom: 0.375rem;
}

/* Filters accordion */
.news-editor__filters {
  margin-top: 1rem;
}

.news-editor__filters-title {
  font-size: 0.875rem !important;
  font-weight: 500 !important;
  color: var(--color-text-secondary) !important;
  min-height: 48px !important;
}

.news-editor__filters-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1rem;
  padding-top: 0.5rem;
}

/* Period selector */
.news-editor__period {
  position: relative;
}

.news-editor__period-display {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  background: var(--color-bg-tertiary, #f3f4f6);
  border: 1px solid var(--color-border, #e5e7eb);
  border-radius: 0.75rem;
  font-size: 0.875rem;
  color: var(--color-text-primary);
  cursor: pointer;
  transition: all 0.2s ease;
}

.news-editor__period-display:hover {
  border-color: var(--color-accent);
  background: var(--color-bg-hover);
}

:root.dark .news-editor__period-display {
  background: var(--color-bg-tertiary, #262626);
  border-color: var(--color-border, #404040);
}

.news-editor__period-display .iconify:first-child {
  font-size: 1.125rem;
  color: var(--color-accent);
}

.news-editor__period-chevron {
  margin-left: auto;
  font-size: 1.25rem;
  color: var(--color-text-secondary);
  transition: transform 0.2s ease;
}

.news-editor__period-chevron--open {
  transform: rotate(180deg);
}

.news-editor__period-dropdown {
  margin-top: 0.5rem;
  padding: 1rem;
  background: var(--color-bg-secondary, #fff);
  border: 1px solid var(--color-border, #e5e7eb);
  border-radius: 0.75rem;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

:root.dark .news-editor__period-dropdown {
  background: var(--color-bg-secondary, #1e1e1e);
  border-color: var(--color-border, #333);
}

.news-editor__period-presets,
.news-editor__period-custom {
  display: flex;
  flex-direction: column;
  gap: 0.625rem;
}

.news-editor__period-label {
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.news-editor__period-buttons {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.news-editor__period-dates {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.75rem;
}

/* Chips container для мультиселекта */
.news-editor__chips-container {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  padding: 0.75rem;
  background: var(--color-bg-tertiary, #f3f4f6);
  border: 1px solid var(--color-border, #e5e7eb);
  border-radius: 0.75rem;
  min-height: 48px;
}

:root.dark .news-editor__chips-container {
  background: var(--color-bg-tertiary, #262626);
  border-color: var(--color-border, #404040);
}

.news-editor__chip {
  cursor: pointer;
  transition: all 0.15s ease;
}

.news-editor__chip:hover {
  transform: scale(1.05);
}

/* Content blocks section */
.news-editor__blocks {
  background: var(--color-bg-secondary, #fff);
  border-radius: 16px;
  padding: 1.5rem;
  border: 1px solid var(--color-border, #e5e7eb);
}

:root.dark .news-editor__blocks {
  background: var(--color-bg-secondary, #1e1e1e);
  border-color: var(--color-border, #333);
}

.news-editor__blocks-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
  flex-wrap: wrap;
  gap: 0.75rem;
}

.news-editor__blocks-title {
  display: flex;
  align-items: center;
  gap: 0.625rem;
}

.news-editor__blocks-title h3 {
  font-size: 1.0625rem;
  font-weight: 600;
  margin: 0;
}

.news-editor__blocks-actions {
  display: flex;
  gap: 0.5rem;
}

.news-editor__blocks-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 3rem 1rem;
  text-align: center;
  color: var(--color-text-secondary, #9ca3af);
}

.news-editor__blocks-empty-icon {
  opacity: 0.3;
  margin-bottom: 1rem;
}

.news-editor__blocks-empty p {
  font-weight: 500;
  margin: 0 0 0.25rem;
}

.news-editor__blocks-empty span {
  font-size: 0.8125rem;
}

.news-editor__blocks-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

/* Individual block */
.news-editor__block {
  background: var(--color-bg-tertiary, #f9fafb);
  border-radius: 12px;
  padding: 1rem;
  border: 1px solid var(--color-border, #e5e7eb);
  transition: transform 0.2s cubic-bezier(0.2, 0, 0, 1), 
              box-shadow 0.2s ease, 
              opacity 0.2s ease,
              border-color 0.2s ease;
  cursor: grab;
}

.news-editor__block:active {
  cursor: grabbing;
}

:root.dark .news-editor__block {
  background: var(--color-bg-tertiary, #262626);
  border-color: var(--color-border, #404040);
}

.news-editor__block:hover {
  border-color: var(--color-primary, #C2E12E);
}

.news-editor__block-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 0.75rem;
}

.news-editor__block-header-left {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.news-editor__block-drag-handle {
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-text-muted);
  opacity: 0.4;
  cursor: grab;
  transition: opacity 0.15s ease, color 0.15s ease;
  padding: 0.25rem;
  border-radius: 4px;
}

.news-editor__block:hover .news-editor__block-drag-handle {
  opacity: 1;
  color: var(--color-accent);
}

.news-editor__block-drag-handle:active {
  cursor: grabbing;
}

/* Drag & Drop стили для блоков */
.news-editor__blocks-list--dragging .news-editor__block:not(.news-editor__block--dragging) {
  transition: transform 0.2s cubic-bezier(0.2, 0, 0, 1);
}

.news-editor__block--dragging {
  opacity: 0.5;
  transform: scale(0.98);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
  z-index: 10;
  position: relative;
  background: var(--color-bg-secondary);
}

.news-editor__block-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.25rem 0.625rem;
  border-radius: 6px;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.025em;
}

.news-editor__block-badge--text {
  background: rgba(99, 102, 241, 0.1);
  color: #6366f1;
}

.news-editor__block-badge--media {
  background: rgba(16, 185, 129, 0.1);
  color: #10b981;
}

/* Media blocks */
.news-editor__media-dropzone {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 200px;
  padding: 1.5rem;
  border: 2px dashed var(--color-border, #d1d5db);
  border-radius: 10px;
  background: var(--color-bg-secondary, #fff);
  box-sizing: border-box;
}

:root.dark .news-editor__media-dropzone {
  background: var(--color-bg-secondary, #1e1e1e);
}

.news-editor__media-preview {
  border-radius: 10px;
  overflow: hidden;
  background: #000;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Ограничение высоты медиафайлов */
.news-editor__media-image,
.news-editor__media-video {
  width: 100%;
  max-height: 400px;
  object-fit: contain;
  display: block;
}

/* Block list animations */
.block-list-enter-active,
.block-list-leave-active {
  transition: all 0.3s ease;
}

.block-list-enter-from {
  opacity: 0;
  transform: translateY(-20px);
}

.block-list-leave-to {
  opacity: 0;
  transform: translateX(20px);
}

.block-list-move {
  transition: transform 0.3s ease;
}

/* ===== COMPRESSION INFO ===== */
.compression-info {
  margin-top: 1rem;
  padding: 1rem;
  border-radius: 0.75rem;
  background-color: var(--color-bg-tertiary);
  border: 1px solid var(--color-border);
}

.compression-info__title {
  font-weight: 600;
  font-size: 1rem;
  margin-bottom: 0.75rem;
  color: var(--color-text-primary);
}

.compression-info__text {
  font-size: 0.875rem;
  color: var(--color-text-secondary);
  margin-bottom: 0.25rem;
}

.compression-info__value {
  font-weight: 500;
  color: var(--color-text-primary);
}

.compression-info__progress {
  margin-top: 0.75rem;
}

.compression-info__progress-header {
  display: flex;
  justify-content: space-between;
  font-size: 0.875rem;
  color: var(--color-text-secondary);
  margin-bottom: 0.5rem;
}

.compression-info__percent {
  font-weight: 600;
  color: var(--color-accent);
}

.compression-info__progress-track {
  width: 100%;
  height: 0.625rem;
  background-color: var(--color-bg-hover);
  border-radius: 9999px;
  overflow: hidden;
}

.compression-info__progress-bar {
  height: 100%;
  background: linear-gradient(90deg, var(--color-accent), var(--color-accent-light, var(--color-accent)));
  border-radius: 9999px;
  transition: width 0.3s ease;
}
</style>
