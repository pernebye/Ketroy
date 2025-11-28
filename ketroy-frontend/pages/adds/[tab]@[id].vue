<template>
  <div class="adds-edit-page">
    <div class="adds-edit-page__header">
      <v-breadcrumbs :items="brItems" class="adds-edit-page__breadcrumbs">
        <template v-slot:divider>
          <icon name="bi:caret-right-fill" />
        </template>
      </v-breadcrumbs>
      <btn text="Сохранить" prepend-icon="mdi-plus" :loading="loading" @click="save" />
    </div>
    <v-form ref="form" class="adds-edit-page__form">
      <fade>
        <section v-if="which === 'discounts'" class="adds-edit-page__content" :class="{ 'adds-edit-page__content--no-sidebar': discount.type === 'birthday' }">
          <div v-if="discount.type !== 'birthday'" ref="sidebarRef" class="adds-edit-page__sidebar">
            <card-form class="gift-catalog">
              <p class="gift-catalog__title">Выбор подарков из каталога</p>
              
              <!-- Для friend_discount показываем интервалы -->
              <template v-if="discount.type === 'friend_discount'">
                <p class="gift-catalog__subtitle">
                  Интервал: 
                  <strong>
                    {{ currentInterval?.minAmount.toLocaleString('ru-RU') }}
                    <span v-if="currentInterval?.maxAmount">
                      — {{ currentInterval.maxAmount.toLocaleString('ru-RU') }}₸
                    </span>
                    <span v-else>₸+</span>
                  </strong>
                </p>

                <!-- Бейджики интервалов для переключения -->
                <div class="gift-catalog__interval-badges">
                  <button
                    v-for="interval in purchaseIntervals"
                    :key="interval.id"
                    class="gift-catalog__interval-badge-btn"
                    :class="{ 'gift-catalog__interval-badge-btn--active': selectedIntervalId === interval.id }"
                    @click="selectedIntervalId = interval.id"
                  >
                    {{ interval.minAmount.toLocaleString('ru-RU') }}
                    <span v-if="interval.maxAmount">
                      —{{ interval.maxAmount.toLocaleString('ru-RU') }}₸
                    </span>
                    <span v-else>₸+</span>
                  </button>
                </div>

                <p class="gift-catalog__subtitle-small">Выберите до 4 подарков для этого интервала:</p>
              </template>

              <!-- Для других типов акций -->
              <p v-else class="gift-catalog__subtitle">Выберите до 4 подарков для этой акции:</p>
              
              <div v-if="availableGifts.length === 0" class="gift-catalog__empty">
                <icon name="mdi:gift-outline" class="gift-catalog__empty-icon" />
                <p>В каталоге пока нет подарков</p>
                <button type="button" class="gift-catalog__link" @click="openAddGiftModal">
                  Добавить первый подарок
                </button>
              </div>
              
              <div v-else class="gift-catalog__list">
                <div 
                  v-for="gift in availableGifts" 
                  :key="gift.id"
                  class="gift-catalog__item"
                  :class="{ 'gift-catalog__item--selected': isGiftSelected(gift.id) }"
                  @click="toggleGiftSelection(gift.id)"
                >
                  <v-checkbox
                    :model-value="isGiftSelected(gift.id)"
                    hide-details
                    density="compact"
                    :disabled="!isGiftSelected(gift.id) && getCurrentSelectedCount() >= 4"
                    @click.stop="toggleGiftSelection(gift.id)"
                  />
                  <img 
                    v-if="gift.image_url" 
                    :src="gift.image_url" 
                    :alt="gift.name"
                    class="gift-catalog__item-image"
                  />
                  <div v-else class="gift-catalog__item-placeholder">
                    <icon name="mdi:gift" />
                  </div>
                  <div class="gift-catalog__item-info">
                    <p class="gift-catalog__item-name">{{ gift.name }}</p>
                    <p v-if="gift.description" class="gift-catalog__item-desc">{{ gift.description }}</p>
                  </div>
                </div>
              </div>
              
              <p class="gift-catalog__counter">
                Выбрано: <span>{{ getCurrentSelectedCount() }}</span> из 4
              </p>

              <div class="gift-catalog__add-new">
                <button type="button" class="gift-catalog__add-link" @click="openAddGiftModal">
                  <icon name="mdi:plus-circle" />
                  Добавить новый подарок в каталог
                </button>
              </div>
            </card-form>
          </div>

          <div ref="mainContentRef" class="adds-edit-page__main">
            <card-form class="discount-form">
              <p class="discount-form__title">Общая информация</p>
              <div class="discount-form__fields">
                <span class="discount-form__label">
                  Название
                  <span v-if="isNameLocked" class="discount-form__locked-badge">🔒 Автоматическое</span>
                </span>
                <v-text-field
                  v-model.trim="discount.name"
                  :disabled="isNameLocked"
                  density="compact"
                  variant="outlined"
                  placeholder="Введите здесь название..."
                  rounded="lg"
                  :rules="[rules.requiredText]"
                  class="discount-form__input"
                  :class="{ 'discount-form__input--disabled': isNameLocked }"
                />

                <span class="discount-form__label">Тип</span>
                <v-select
                  v-model="discount.type"
                  :items="types"
                  density="compact"
                  variant="outlined"
                  placeholder="Выберите тип"
                  :persistent-placeholder="true"
                  rounded="lg"
                  :rules="[rules.requiredText]"
                  item-value="key"
                  item-title="value"
                  class="discount-form__input"
                />

                <!-- Тумблер активности -->
                <span class="discount-form__label">Статус</span>
                <div class="discount-form__toggle-row">
                  <div class="discount-form__toggle-wrapper">
                    <v-switch
                      v-model="discount.is_active"
                      density="compact"
                      color="primary"
                      class="discount-form__switch"
                    />
                    <span class="discount-form__toggle-label">
                      {{ discount.is_active ? 'Активна' : 'Неактивна' }}
                    </span>
                  </div>
                </div>

                <!-- Период для всех типов кроме "Лотерея по датам" и "День рождения" -->
                <template v-if="discount.type !== 'date_based' && discount.type !== 'birthday'">
                  <span class="discount-form__label">Период действия</span>
                  <div class="discount-form__period-buttons">
                    <v-btn
                      v-for="preset in periodPresets"
                      :key="preset.id"
                      size="small"
                      :variant="getPeriodButtonVariant(preset.id)"
                      @click="applyPeriodPreset(preset)"
                    >
                      {{ preset.label }}
                    </v-btn>
                  </div>
                  <DatePickerComponent 
                    range 
                    v-model="discount.dates" 
                    placeholder="Выберите период действия акции"
                  />
                </template>

                <!-- По разовой покупке -->
                <div v-if="discount.type === 'single_purchase'" class="discount-form__type-settings">
                  <span class="discount-form__label">Минимальная сумма покупки (₸)</span>
                  <v-text-field
                    v-model.trim="discount.price"
                    density="compact"
                    type="number"
                    variant="outlined"
                    placeholder="Например: 300000"
                    rounded="lg"
                    :rules="[rules.requiredText]"
                    class="discount-form__input"
                  />
                  <p class="discount-form__hint">Клиент получит подарок при разовой покупке на эту сумму</p>
                </div>

                <!-- Подари скидку другу -->
                <div v-if="discount.type === 'friend_discount'" class="discount-form__type-settings discount-form__referral">
                  <div class="discount-form__referral-alert">
                    <icon name="mdi:information" class="discount-form__referral-icon" />
                    <span>Можно создать только одну акцию этого типа. При изменении настроек, для уже зарегистрированных рефералов будут действовать настройки на момент применения промокода.</span>
                  </div>

                  <!-- Секция: Для нового пользователя (применившего промокод) -->
                  <div class="discount-form__section">
                    <h4 class="discount-form__section-title">
                      <icon name="mdi:account-plus" />
                      Для нового пользователя (применившего промокод)
                    </h4>
                    
                    <span class="discount-form__label">Скидка для нового пользователя (%)</span>
                    <v-text-field
                      v-model.number="discount.newUserDiscountPercent"
                      density="compact"
                      type="number"
                      variant="outlined"
                      placeholder="10"
                      rounded="lg"
                      class="discount-form__input"
                      min="0"
                      max="100"
                    />

                    <div class="discount-form__row">
                      <div class="discount-form__col">
                        <span class="discount-form__label">Бонусы с покупок (%)</span>
                        <v-text-field
                          v-model.number="discount.newUserBonusPercent"
                          density="compact"
                          type="number"
                          variant="outlined"
                          placeholder="5"
                          rounded="lg"
                          class="discount-form__input"
                          min="0"
                          max="100"
                        />
                      </div>
                      <div class="discount-form__col">
                        <span class="discount-form__label">За первые N покупок</span>
                        <v-text-field
                          v-model.number="discount.newUserBonusPurchases"
                          density="compact"
                          type="number"
                          variant="outlined"
                          placeholder="1"
                          rounded="lg"
                          class="discount-form__input"
                          min="1"
                          max="100"
                        />
                      </div>
                    </div>
                  </div>

                  <!-- Секция: Для реферера (владельца промокода) -->
                  <div class="discount-form__section">
                    <h4 class="discount-form__section-title">
                      <icon name="mdi:account-star" />
                      Для реферера (владельца промокода)
                    </h4>
                    
                    <div class="discount-form__row">
                      <div class="discount-form__col">
                        <span class="discount-form__label">Бонусы с покупок друга (%)</span>
                        <v-text-field
                          v-model.number="discount.referrerBonusPercent"
                          density="compact"
                          type="number"
                          variant="outlined"
                          placeholder="2"
                          rounded="lg"
                          class="discount-form__input"
                          min="0"
                          max="100"
                        />
                      </div>
                      <div class="discount-form__col">
                        <span class="discount-form__label">За первые N покупок друга</span>
                        <v-text-field
                          v-model.number="discount.referrerMaxPurchases"
                          density="compact"
                          type="number"
                          variant="outlined"
                          placeholder="3"
                          rounded="lg"
                          class="discount-form__input"
                          min="1"
                          max="100"
                        />
                      </div>
                    </div>
                  </div>

                  <!-- Секция: Для рефереров с высокой скидкой -->
                  <div class="discount-form__section discount-form__section--highlight">
                    <h4 class="discount-form__section-title">
                      <icon name="mdi:gift" />
                      Рефереры с высокой скидкой (подарки вместо бонусов)
                    </h4>
                    
                    <p class="discount-form__hint">
                      Рефереры с персональной скидкой ≥ указанного порога получают подарки вместо бонусов
                    </p>
                    
                    <span class="discount-form__label">Порог персональной скидки (%)</span>
                    <v-text-field
                      v-model.number="discount.referrerHighDiscountThreshold"
                      density="compact"
                      type="number"
                      variant="outlined"
                      placeholder="30"
                      rounded="lg"
                      class="discount-form__input"
                      min="0"
                      max="100"
                    />

                    <!-- Интервалы сумм -->
                    <div class="discount-form__intervals">
                      <span class="discount-form__label">Интервалы сумм покупок</span>
                      <p class="discount-form__hint">Выберите интервал в панели справа, затем добавьте для него подарки</p>
                      
                      <div class="discount-form__intervals-list">
                        <div
                          v-for="(interval, idx) in purchaseIntervals"
                          :key="interval.id"
                          class="discount-form__interval-item"
                          :class="{ 'discount-form__interval-item--active': selectedIntervalId === interval.id }"
                          @click="selectedIntervalId = interval.id"
                        >
                          <div class="discount-form__interval-inputs">
                            <div class="discount-form__interval-input-group">
                              <span class="discount-form__interval-label">От</span>
                              <v-text-field
                                v-model.number="interval.minAmount"
                                type="number"
                                density="compact"
                                variant="outlined"
                                hide-details
                                suffix="₸"
                                class="discount-form__interval-input"
                                @click.stop
                              />
                            </div>
                            <div class="discount-form__interval-input-group">
                              <span class="discount-form__interval-label">До</span>
                              <v-text-field
                                v-if="idx < purchaseIntervals.length - 1"
                                v-model.number="interval.maxAmount"
                                type="number"
                                density="compact"
                                variant="outlined"
                                hide-details
                                suffix="₸"
                                class="discount-form__interval-input"
                                @click.stop
                              />
                              <div v-else class="discount-form__interval-infinity">
                                <icon name="mdi:infinity" />
                              </div>
                            </div>
                          </div>
                          <div class="discount-form__interval-badges">
                            <span class="discount-form__interval-badge">
                              Подарков: {{ interval.giftIds.length }}
                            </span>
                            <v-btn
                              v-if="purchaseIntervals.length > 1"
                              icon
                              size="small"
                              variant="text"
                              color="error"
                              @click.stop="removeInterval(interval.id)"
                              class="discount-form__interval-delete-btn"
                            >
                              <icon name="mdi:delete" />
                            </v-btn>
                          </div>
                        </div>
                      </div>

                      <v-btn
                        variant="tonal"
                        size="small"
                        prepend-icon="mdi:plus"
                        @click="addInterval"
                        class="discount-form__btn-add-interval"
                      >
                        Добавить интервал
                      </v-btn>
                    </div>
                    
                    <p class="discount-form__hint discount-form__hint--info">
                      Подарки для интервалов выбираются из панели справа (случайный выбор внутри интервала)
                    </p>
                  </div>

                  <!-- Превью -->
                  <div class="discount-form__preview">
                    <h5>Предпросмотр условий:</h5>
                    <ul>
                      <li>🎁 Новый пользователь получит: скидку {{ discount.newUserDiscountPercent || 10 }}% + {{ discount.newUserBonusPercent || 5 }}% бонусов с {{ getCorrectEnding(discount.newUserBonusPurchases || 1, 'первой', 'первых', 'первых') }} {{ discount.newUserBonusPurchases || 1 }} {{ getPurchaseWord(discount.newUserBonusPurchases || 1) }}</li>
                      <li>💰 Реферер получит: {{ discount.referrerBonusPercent || 2 }}% бонусов с {{ getCorrectEnding(discount.referrerMaxPurchases || 3, 'первой', 'первых', 'первых') }} {{ discount.referrerMaxPurchases || 3 }} {{ getPurchaseWord(discount.referrerMaxPurchases || 3) }} друга</li>
                      <li>🎀 Рефереры со скидкой ≥{{ discount.referrerHighDiscountThreshold || 30 }}%: получат случайный подарок</li>
                    </ul>
                  </div>
                </div>

                <!-- Лотерея по датам -->
                <div v-if="discount.type === 'date_based'" class="discount-form__type-settings discount-form__lottery">
                  <span class="discount-form__label">Период проведения акции</span>
                  <DatePickerComponent 
                    range 
                    v-model="discount.dates" 
                    placeholder="Выберите даты проведения лотереи"
                  />
                  <p class="discount-form__hint">Пользователи, которые зайдут в приложение в этот период, увидят модальное окно с подарком</p>

                  <!-- Разделитель -->
                  <div class="discount-form__divider">
                    <span>Push-уведомление</span>
                  </div>

                  <span class="discount-form__label">Заголовок push-уведомления</span>
                  <v-text-field
                    v-model.trim="discount.push_title"
                    density="compact"
                    variant="outlined"
                    placeholder="У вас подарок! 🎁"
                    rounded="lg"
                    class="discount-form__input"
                  />

                  <span class="discount-form__label">Текст push-уведомления</span>
                  <v-textarea
                    v-model.trim="discount.push_text"
                    density="compact"
                    variant="outlined"
                    placeholder="Зайдите в приложение, чтобы получить свой подарок!"
                    rounded="lg"
                    rows="2"
                    class="discount-form__input"
                  />

                  <span class="discount-form__label">Дата и время отправки push-уведомления</span>
                  <DatePickerComponent 
                    v-model="discount.push_send_at" 
                    placeholder="Выберите дату и время"
                    :enable-time="true"
                  />
                  <p class="discount-form__hint">Оставьте пустым, если не хотите отправлять push-уведомление</p>

                  <!-- Разделитель -->
                  <div class="discount-form__divider">
                    <span>Модальное окно</span>
                  </div>

                  <span class="discount-form__label">Заголовок модального окна</span>
                  <v-text-field
                    v-model.trim="discount.modal_title"
                    density="compact"
                    variant="outlined"
                    placeholder="Поздравляем! 🎉"
                    rounded="lg"
                    class="discount-form__input"
                  />

                  <span class="discount-form__label">Текст модального окна</span>
                  <v-textarea
                    v-model.trim="discount.modal_text"
                    density="compact"
                    variant="outlined"
                    placeholder="Вы получили подарок! Нажмите на кнопку ниже, чтобы выбрать его."
                    rounded="lg"
                    rows="3"
                    class="discount-form__input"
                  />

                  <span class="discount-form__label">Текст кнопки</span>
                  <v-text-field
                    v-model.trim="discount.modal_button_text"
                    density="compact"
                    variant="outlined"
                    placeholder="Получить подарок"
                    rounded="lg"
                    class="discount-form__input"
                  />

                  <span class="discount-form__label">Изображение модального окна</span>
                  <div class="discount-form__image-upload">
                    <div v-if="discount.modal_image" class="discount-form__image-preview">
                      <img :src="discount.modal_image" alt="Modal image" />
                      <v-btn 
                        icon="mdi-close" 
                        size="small" 
                        variant="flat" 
                        color="error"
                        class="discount-form__image-remove"
                        @click="discount.modal_image = ''"
                      />
                    </div>
                    <v-file-input
                      v-else
                      accept="image/*"
                      density="compact"
                      variant="outlined"
                      prepend-icon=""
                      prepend-inner-icon="mdi-camera"
                      placeholder="Загрузить изображение"
                      rounded="lg"
                      class="discount-form__input"
                      @change="handleModalImageUpload"
                    />
                  </div>
                  <p class="discount-form__hint">Изображение будет показано в центре модального окна</p>
                </div>

                <!-- День рождения -->
                <div v-if="discount.type === 'birthday'" class="discount-form__type-settings discount-form__birthday">
                  <div class="discount-form__birthday-alert">
                    <icon name="mdi:information" class="discount-form__birthday-icon" />
                    <span>Можно создать только одну акцию этого типа. Размер и длительность скидки определяются на стороне 1С. Здесь вы настраиваете push-уведомления, которые будут отправляться пользователям.</span>
                  </div>
                  
                  <!-- Push-уведомления -->
                  <div class="discount-form__notifications-section">
                    <div class="discount-form__notifications-header">
                      <h4>
                        <icon name="mdi:bell-ring" />
                        Push-уведомления
                      </h4>
                      <btn
                        text="Добавить push-уведомление"
                        prepend-icon="mdi-plus"
                        size="small"
                        @click="addBirthdayNotification"
                      />
                    </div>
                    
                    <p v-if="birthdayNotifications.length === 0" class="discount-form__notifications-empty">
                      Нет настроенных уведомлений. Нажмите кнопку выше, чтобы добавить.
                    </p>
                    
                    <TransitionGroup name="notification-item" tag="div" class="discount-form__notifications-list">
                      <div 
                        v-for="(notification, index) in birthdayNotifications" 
                        :key="notification.id"
                        class="discount-form__notification-card"
                      >
                        <div class="discount-form__notification-header">
                          <span class="discount-form__notification-number">Уведомление #{{ index + 1 }}</span>
                          <v-btn
                            icon
                            size="small"
                            variant="text"
                            color="error"
                            @click="removeBirthdayNotification(notification.id)"
                          >
                            <icon name="mdi:delete" />
                          </v-btn>
                        </div>
                        
                        <div class="discount-form__notification-timing">
                          <div class="discount-form__notification-timing-field">
                            <span class="discount-form__label">За сколько дней до ДР</span>
                            <v-text-field
                              v-model.number="notification.days_before"
                              density="compact"
                              type="number"
                              variant="outlined"
                              placeholder="2"
                              rounded="lg"
                              class="discount-form__input"
                              min="0"
                              max="30"
                              hide-details
                            />
                          </div>
                          <div class="discount-form__notification-timing-field">
                            <span class="discount-form__label">Время отправки</span>
                            <v-text-field
                              v-model="notification.send_time"
                              density="compact"
                              type="time"
                              variant="outlined"
                              rounded="lg"
                              class="discount-form__input"
                              hide-details
                            />
                          </div>
                        </div>
                        
                        <span class="discount-form__label">Заголовок уведомления</span>
                        <v-text-field
                          v-model.trim="notification.title"
                          density="compact"
                          variant="outlined"
                          placeholder="С днем рождения!"
                          rounded="lg"
                          class="discount-form__input"
                          hide-details
                        />
                        
                        <span class="discount-form__label">Текст уведомления</span>
                        <v-textarea
                          v-model.trim="notification.body"
                          density="compact"
                          variant="outlined"
                          placeholder="Поздравляем с наступающим днем рождения..."
                          rounded="lg"
                          rows="2"
                          class="discount-form__input"
                          hide-details
                        />
                        
                        <p class="discount-form__notification-preview">
                          <icon name="mdi:calendar-clock" />
                          Будет отправлено за <strong>{{ notification.days_before || 0 }}</strong> {{ getDaysWord(notification.days_before || 0) }} до ДР в <strong>{{ notification.send_time || '10:00' }}</strong>
                        </p>
                      </div>
                    </TransitionGroup>
                  </div>
                </div>

                <span class="discount-form__label discount-form__label--mt">
                  Описание
                  <span v-if="isDescriptionLocked" class="discount-form__locked-badge">🔒 Фиксированное</span>
                </span>
                <v-textarea
                  v-model.trim="discount.description"
                  :disabled="isDescriptionLocked"
                  density="compact"
                  variant="outlined"
                  placeholder="Введите здесь описание..."
                  rounded="lg"
                  :rules="[rules.requiredText]"
                  class="discount-form__input"
                  :class="{ 'discount-form__input--disabled': isDescriptionLocked }"
                />
              </div>
            </card-form>
          </div>
        </section>
      </fade>
    <fade>
      <section v-if="which === 'prizes'" class="adds-edit-page__content">
        <card-form class="prize-image-form">
          <p class="prize-image-form__title">
            Изображение подарка
            <fade>
              <v-btn v-if="giftCatalog.image" variant="plain" icon="mdi-close" density="compact" @click="giftCatalog.image = ''" class="prize-image-form__remove-btn">
                <icon class="prize-image-form__remove-icon" name="mage:trash-square-fill" />
              </v-btn>
            </fade>
          </p>
          <div class="prize-image-form__content">
            <fade>
              <file-input v-if="!giftCatalog.image" v-model="giftImage" class="prize-image-form__upload" accept="image/*" @handlePhotoUpload="handleGiftPhotoUpload">
                <svg width="44" height="45" viewBox="0 0 44 45" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <rect y="0.5" width="44" height="44" rx="8" fill="currentColor" class="prize-image-form__icon-bg" />
                  <g clip-path="url(#clip0_0_7857)">
                    <path d="M21.3416 22.9017C21.1326 22.6926 20.8845 22.5268 20.6115 22.4136C20.3384 22.3004 20.0457 22.2422 19.7501 22.2422C19.4545 22.2422 19.1618 22.3004 18.8887 22.4136C18.6156 22.5268 18.3675 22.6926 18.1586 22.9017L13.0286 28.0317C13.0979 28.9723 13.5198 29.852 14.2097 30.495C14.8997 31.138 15.807 31.4968 16.7501 31.4997H27.2501C27.9849 31.4996 28.7032 31.2822 29.3148 30.875L21.3416 22.9017Z" fill="white" />
                    <path d="M26.4999 19.5C27.3283 19.5 27.9999 18.8284 27.9999 18C27.9999 17.1716 27.3283 16.5 26.4999 16.5C25.6715 16.5 24.9999 17.1716 24.9999 18C24.9999 18.8284 25.6715 19.5 26.4999 19.5Z" fill="white" />
                    <path d="M27.25 13.5H16.75C15.7558 13.5012 14.8027 13.8967 14.0997 14.5997C13.3967 15.3027 13.0012 16.2558 13 17.25L13 25.9395L17.098 21.8415C17.4462 21.4932 17.8597 21.2169 18.3147 21.0283C18.7697 20.8398 19.2575 20.7428 19.75 20.7428C20.2425 20.7428 20.7303 20.8398 21.1853 21.0283C21.6403 21.2169 22.0538 21.4932 22.402 21.8415L30.3752 29.8148C30.7825 29.2031 30.9999 28.4848 31 27.75V17.25C30.9988 16.2558 30.6033 15.3027 29.9003 14.5997C29.1973 13.8967 28.2442 13.5012 27.25 13.5V13.5ZM26.5 21C25.9067 21 25.3266 20.8241 24.8333 20.4944C24.3399 20.1648 23.9554 19.6962 23.7284 19.1481C23.5013 18.5999 23.4419 17.9967 23.5576 17.4147C23.6734 16.8328 23.9591 16.2982 24.3787 15.8787C24.7982 15.4591 25.3328 15.1734 25.9147 15.0576C26.4967 14.9419 27.0999 15.0013 27.648 15.2284C28.1962 15.4554 28.6648 15.8399 28.9944 16.3333C29.3241 16.8266 29.5 17.4067 29.5 18C29.5 18.7956 29.1839 19.5587 28.6213 20.1213C28.0587 20.6839 27.2956 21 26.5 21Z" fill="white" />
                  </g>
                </svg>
                <span class="prize-image-form__upload-text">Перетащите изображение или нажмите для загрузки</span>
              </file-input>
            </fade>
            <fade>
              <div v-if="giftCatalog.image" class="prize-image-form__preview">
                <img :src="giftCatalog.image" alt="Gift Image" class="prize-image-form__image" draggable="false" />
              </div>
            </fade>
          </div>
        </card-form>
        <card-form class="prize-info-form">
          <p class="prize-info-form__title">Информация о подарке</p>
          <div class="prize-info-form__fields">
            <span class="prize-info-form__label">Название подарка</span>
            <v-text-field
              v-model.trim="giftCatalog.name"
              density="compact"
              variant="outlined"
              placeholder="Например: Галстук, Рубашка, Ремень..."
              rounded="lg"
              :rules="[rules.requiredText]"
              class="prize-info-form__input"
            />
            <span class="prize-info-form__label">Описание (необязательно)</span>
            <v-textarea
              v-model.trim="giftCatalog.description"
              density="compact"
              variant="outlined"
              placeholder="Краткое описание подарка..."
              rounded="lg"
              rows="3"
              class="prize-info-form__input"
            />
          </div>
        </card-form>
      </section>
    </fade>
  </v-form>
  </div>

  <!-- Модальное окно добавления подарка -->
  <v-dialog v-model="showAddGiftModal" max-width="460" persistent>
    <v-card class="add-gift-modal">
      <v-card-title class="add-gift-modal__title">
        <icon name="mdi:gift-outline" class="add-gift-modal__title-icon" />
        Новый подарок
        <v-btn icon variant="text" size="small" @click="closeAddGiftModal" class="add-gift-modal__close">
          <icon name="mdi:close" />
        </v-btn>
      </v-card-title>
      
      <v-card-text class="add-gift-modal__content">
        <!-- Изображение -->
        <div class="add-gift-modal__image-section">
          <fade>
            <file-input 
              v-if="!newGiftData.image" 
              v-model="newGiftImage" 
              class="add-gift-modal__upload" 
              accept="image/*" 
              @handlePhotoUpload="handleNewGiftPhotoUpload"
            >
              <icon name="mdi:image-plus" class="add-gift-modal__upload-icon" />
              <span class="add-gift-modal__upload-text">Загрузить фото</span>
            </file-input>
          </fade>
          <fade>
            <div v-if="newGiftData.image" class="add-gift-modal__preview">
              <img :src="newGiftData.image" alt="Preview" class="add-gift-modal__preview-image" />
              <v-btn 
                icon 
                variant="flat" 
                size="x-small" 
                color="error" 
                class="add-gift-modal__preview-remove"
                @click="newGiftData.image = ''"
              >
                <icon name="mdi:close" />
              </v-btn>
            </div>
          </fade>
        </div>

        <!-- Поля формы -->
        <v-text-field
          v-model.trim="newGiftData.name"
          label="Название подарка"
          placeholder="Например: Галстук, Рубашка..."
          variant="outlined"
          density="compact"
          rounded="lg"
          hide-details="auto"
          class="add-gift-modal__input"
        />
        
        <v-textarea
          v-model.trim="newGiftData.description"
          label="Описание (необязательно)"
          placeholder="Краткое описание..."
          variant="outlined"
          density="compact"
          rounded="lg"
          rows="2"
          hide-details
          class="add-gift-modal__input"
        />
      </v-card-text>
      
      <v-card-actions class="add-gift-modal__actions">
        <v-btn 
          variant="text" 
          @click="closeAddGiftModal"
          :disabled="addGiftLoading"
        >
          Отмена
        </v-btn>
        <v-btn 
          color="primary" 
          variant="flat"
          :loading="addGiftLoading"
          :disabled="!newGiftData.name.trim()"
          @click="saveNewGift"
        >
          <icon name="mdi:check" class="mr-1" />
          Сохранить
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { AdminEnums } from '~/types/enums';
import { QuillEditor } from '@vueup/vue-quill';
import '@vueup/vue-quill/dist/vue-quill.snow.css';
import { formatToYYYYMMDD } from '@/utils/formatDate';
import Compressor from 'compressorjs';

const route = useRoute();
const router = useRouter();
const layoutStore = useLayoutStore();

const content = ref<string>('');
const form = ref();
const loading = ref<boolean>(false);

const discount = ref<{
  name: string;
  is_active: boolean;
  type: string | null;
  price: number | null;
  expired_at: string | null;
  description: string;
  dates: string | string[];
  city: string | null;
  // Для акции "День рождения"
  discountPercent: number;
  daysBefore: number;
  durationDays: number;
  // Для акции "Подари скидку другу"
  referrerBonusPercent: number;
  referrerMaxPurchases: number;
  referrerHighDiscountThreshold: number;
  newUserDiscountPercent: number;
  newUserBonusPercent: number;
  newUserBonusPurchases: number;
  // Для лотереи - Push-уведомления
  push_title: string;
  push_text: string;
  push_send_at: string | null;
  // Для лотереи - Модальное окно
  modal_title: string;
  modal_text: string;
  modal_image: string;
  modal_button_text: string;
}>({
  name: '',
  description: '',
  type: null,
  price: null,
  expired_at: '',
  is_active: false,
  dates: '',
  city: null,
  // Значения по умолчанию для ДР
  discountPercent: 30,
  daysBefore: 2,
  durationDays: 5,
  // Значения по умолчанию для реферальной программы
  referrerBonusPercent: 2,
  referrerMaxPurchases: 3,
  referrerHighDiscountThreshold: 30,
  newUserDiscountPercent: 10,
  newUserBonusPercent: 5,
  newUserBonusPurchases: 1,
  // Значения по умолчанию для лотереи
  push_title: '',
  push_text: '',
  push_send_at: null,
  modal_title: '',
  modal_text: '',
  modal_image: '',
  modal_button_text: '',
});

// Для каталога подарков
const giftCatalog = ref<{ name: string; description: string; image: string }>({
  name: '',
  description: '',
  image: '',
});
const giftImage = ref<File | null>(null);
const availableGifts = ref<Api.GiftCatalog.Self[]>([]); // Список подарков из каталога для выбора в акции
const selectedGiftIds = ref<number[]>([]); // Выбранные подарки для акции

// Интервалы сумм для рефереров с высокой скидкой
interface PurchaseInterval {
  id: string;
  minAmount: number;
  maxAmount: number | null; // null для последнего интервала
  giftIds: number[];
}

const purchaseIntervals = ref<PurchaseInterval[]>([
  {
    id: 'interval-1',
    minAmount: 100000,
    maxAmount: null, // Первый интервал всегда бесконечный
    giftIds: []
  }
]);
const selectedIntervalId = ref<string>('interval-1');

// Модальное окно добавления подарка
const showAddGiftModal = ref(false);
const newGiftData = ref({
  name: '',
  description: '',
  image: ''
});
const newGiftImage = ref<File | null>(null);
const addGiftLoading = ref(false);

// Push-уведомления для дня рождения
interface BirthdayNotification {
  id: string;
  days_before: number;
  send_time: string;
  title: string;
  body: string;
}

const birthdayNotifications = ref<BirthdayNotification[]>([]);

// Refs для синхронизации плавающей панели с основным контентом
const sidebarRef = ref<HTMLElement | null>(null);
const mainContentRef = ref<HTMLElement | null>(null);

const placementAreas = ref<Api.Dict[]>([]);
const types = ref([
  { key: 'single_purchase', value: 'По разовой покупке', icon: 'mdi:shopping', description: 'Подарок при покупке на определённую сумму' },
  { key: 'friend_discount', value: 'Подари скидку другу', icon: 'mdi:account-multiple', description: 'Реферальная программа' },
  { key: 'date_based', value: 'Лотерея по датам', icon: 'mdi:calendar-star', description: 'Подарки всем в указанную дату' },
  { key: 'birthday', value: 'День рождения', icon: 'mdi:cake-variant', description: 'Скидка в честь дня рождения клиента' },
]);

// Пресеты для периодов
const periodPresets = ref([
  { id: 'unlimited', label: 'Бессрочно' },
  { id: '7days', label: '7 дней' },
  { id: '14days', label: '14 дней' },
  { id: '30days', label: '30 дней' },
  { id: '90days', label: '90 дней' },
]);

const which = computed(() => String(route.params.tab) as keyof typeof AdminEnums.AddsItems);
const id = computed<number | 'new'>(() => (route.params.id === 'new' ? 'new' : Number(route.params.id)));

// Правила валидации для форм
const rules = {
  requiredText: (value: string | null | undefined) => !!value || 'Это поле обязательно',
};

const brItems: Types.Crumb[] = [
  // { title: t('admin.nav.adds'), to: { name: 'adds' }, disabled: false },
  { title: t(`admin.adds.${which.value}`), to: { name: 'adds', query: { tab: which.value } }, disabled: false },
  { title: (id.value === 'new' ? 'Добавить ' : 'Редактировать ') + t(`admin.adds.${which.value}`), to: { ...route }, disabled: false },
];

const formattedDate = (date: Date) => {
  if (!date || isNaN(date.getTime())) return '';
  return date.toISOString().split('T')[0];
};

// Форматирование даты с временем для push-уведомлений
const formattedDateTime = (date: Date | string | null) => {
  if (!date) return null;
  const d = typeof date === 'string' ? new Date(date) : date;
  if (isNaN(d.getTime())) return null;
  // Формат: YYYY-MM-DD HH:mm:ss
  const pad = (n: number) => n.toString().padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:00`;
};

/**
 * Возвращает правильное окончание слова "покупка" в зависимости от числа
 */
const getPurchaseWord = (count: number): string => {
  const lastDigit = count % 10;
  const lastTwoDigits = count % 100;

  if (lastTwoDigits >= 11 && lastTwoDigits <= 19) {
    return 'покупок'; // 11-19
  }

  if (lastDigit === 1) {
    return 'покупки'; // 1, 21, 31, ...
  }

  if (lastDigit >= 2 && lastDigit <= 4) {
    return 'покупок'; // 2-4, 22-24, ...
  }

  return 'покупок'; // 0, 5-20, 25-30, ...
};

/**
 * Возвращает правильное окончание слова "бонус" или другого существительного
 */
const getCorrectEnding = (count: number, singular: string, dual: string, plural: string): string => {
  const lastDigit = count % 10;
  const lastTwoDigits = count % 100;

  if (lastTwoDigits >= 11 && lastTwoDigits <= 19) {
    return plural; // 11-19
  }

  if (lastDigit === 1) {
    return singular; // 1, 21, 31, ...
  }

  if (lastDigit >= 2 && lastDigit <= 4) {
    return dual; // 2-4, 22-24, ...
  }

  return plural; // 0, 5-20, 25-30, ...
};

/**
 * Вычисляемое свойство для определения, нужно ли блокировать поле названия
 */
const isNameLocked = computed(() => {
  return discount.value.type === 'friend_discount' || discount.value.type === 'birthday';
});

/**
 * Склонение слова "день"
 */
const getDaysWord = (count: number): string => {
  const lastDigit = count % 10;
  const lastTwoDigits = count % 100;

  if (lastTwoDigits >= 11 && lastTwoDigits <= 19) {
    return 'дней';
  }

  if (lastDigit === 1) {
    return 'день';
  }

  if (lastDigit >= 2 && lastDigit <= 4) {
    return 'дня';
  }

  return 'дней';
};

/**
 * Добавить новое push-уведомление для дня рождения
 */
const addBirthdayNotification = () => {
  birthdayNotifications.value.push({
    id: `notif-${Date.now()}`,
    days_before: 2,
    send_time: '10:00',
    title: 'С днем рождения! 🎂',
    body: 'Поздравляем с наступающим днем рождения и дарим вам скидку -30% на все покупки, скидка активна 5 дней'
  });
};

/**
 * Удалить push-уведомление для дня рождения
 */
const removeBirthdayNotification = (notificationId: string) => {
  const index = birthdayNotifications.value.findIndex(n => n.id === notificationId);
  if (index > -1) {
    birthdayNotifications.value.splice(index, 1);
  }
};

/**
 * Получить фиксированное название акции
 */
const getFixedName = (type: string | null): string => {
  switch (type) {
    case 'friend_discount':
      return 'Подари скидку другу';
    case 'birthday':
      return 'День рождения';
    default:
      return '';
  }
};

/**
 * Получить фиксированное описание акции
 */
const getFixedDescription = (type: string | null): string => {
  switch (type) {
    case 'birthday':
      return 'Поздравляем с наступающим днем рождения и дарим вам скидку -30% на все покупки. Скидка активна 5 дней с момента получения уведомления и действует во всех наших магазинах! Данная скидка не суммируется с акциями в магазине.';
    default:
      return '';
  }
};

/**
 * Вычисляемое свойство для определения, нужно ли блокировать поле описания
 */
const isDescriptionLocked = computed(() => {
  return discount.value.type === 'birthday';
});

/**
 * Watcher для автоматического установления названия и описания при смене типа
 */
watch(() => discount.value.type, (newType, oldType) => {
  if (newType === 'friend_discount' || newType === 'birthday') {
    // Устанавливаем автоматическое название для этих типов
    discount.value.name = getFixedName(newType);
  } else if (oldType === 'friend_discount' || oldType === 'birthday') {
    // Очищаем название, если переключились с автоматического типа на другой
    discount.value.name = '';
  }
  
  // Устанавливаем фиксированное описание для birthday
  if (newType === 'birthday') {
    discount.value.description = getFixedDescription(newType);
  } else if (oldType === 'birthday') {
    // Очищаем описание при смене с birthday на другой тип
    discount.value.description = '';
  }
  
  // При выборе типа birthday - добавляем первое уведомление по умолчанию если список пуст
  if (newType === 'birthday' && birthdayNotifications.value.length === 0) {
    addBirthdayNotification();
  }
  
  // При смене с birthday на другой тип - очищаем уведомления
  if (oldType === 'birthday' && newType !== 'birthday') {
    birthdayNotifications.value = [];
  }
});

/**
 * Computed property для получения текущего выбранного интервала
 */
const currentInterval = computed(() => {
  return purchaseIntervals.value.find(i => i.id === selectedIntervalId.value);
});

/**
 * Добавить новый интервал
 */
const addInterval = () => {
  const lastInterval = purchaseIntervals.value[purchaseIntervals.value.length - 1];
  
  // Устанавливаем верхнюю границу для предыдущего интервала
  // Шаг по умолчанию: +200000 от minAmount
  const newMaxForLast = lastInterval.minAmount + 199999;
  lastInterval.maxAmount = newMaxForLast;
  
  // Новый интервал начинается с maxAmount + 1 и идёт до бесконечности
  purchaseIntervals.value.push({
    id: `interval-${Date.now()}`,
    minAmount: newMaxForLast + 1,
    maxAmount: null, // Последний интервал всегда бесконечный
    giftIds: []
  });
  
  // Выбираем новый интервал
  selectedIntervalId.value = purchaseIntervals.value[purchaseIntervals.value.length - 1].id;
};

/**
 * Удалить интервал
 */
const removeInterval = (intervalId: string) => {
  const index = purchaseIntervals.value.findIndex(i => i.id === intervalId);
  if (index > -1) {
    purchaseIntervals.value.splice(index, 1);
    
    // Если удалили выбранный интервал, выбери первый
    if (selectedIntervalId.value === intervalId) {
      selectedIntervalId.value = purchaseIntervals.value[0]?.id || '';
    }
    
    // Последний интервал всегда должен быть бесконечным
    if (purchaseIntervals.value.length > 0) {
      purchaseIntervals.value[purchaseIntervals.value.length - 1].maxAmount = null;
    }
  }
};

/**
 * Проверить, выбран ли подарок в текущем интервале
 */
const isGiftSelected = (giftId: number): boolean => {
  if (discount.value.type === 'friend_discount' && currentInterval.value) {
    return currentInterval.value.giftIds.includes(giftId);
  }
  return selectedGiftIds.value.includes(giftId);
};

/**
 * Получить количество выбранных подарков в текущем контексте
 */
const getCurrentSelectedCount = (): number => {
  if (discount.value.type === 'friend_discount' && currentInterval.value) {
    return currentInterval.value.giftIds.length;
  }
  return selectedGiftIds.value.length;
};

/**
 * Применить пресет периода
 */
const applyPeriodPreset = (preset: { id: string; label: string }) => {
  const today = new Date();
  let endDate: Date | null = null;

  if (preset.id === 'unlimited') {
    discount.value.dates = '';
    return;
  }

  // Парсим количество дней из id
  const match = preset.id.match(/(\d+)days/);
  if (match) {
    const days = parseInt(match[1]);
    endDate = new Date(today);
    endDate.setDate(endDate.getDate() + days);
  }

  if (endDate) {
    const startStr = formattedDate(today);
    const endStr = formattedDate(endDate);
    discount.value.dates = [startStr, endStr];
  }
};

/**
 * Получить вариант для кнопки периода
 */
const getPeriodButtonVariant = (presetId: string) => {
  if (!discount.value.dates || discount.value.dates === '') {
    return presetId === 'unlimited' ? 'flat' : 'text';
  }
  return 'text';
};

const save = useDebounceFn(
  async () => {
    await form.value.validate().then(async (v: Types.VFormValidation) => {
      if (!v.valid) return;
      loading.value = true;
      try {
        let payload: any = {};
        if (which.value === 'discounts') {
          // Валидация подарков в зависимости от типа акции
          if (discount.value.type === 'friend_discount') {
            // Для friend_discount проверяем, есть ли подарки хотя бы в одном интервале
            const hasGiftsInIntervals = purchaseIntervals.value.some(interval => interval.giftIds.length > 0);
            if (!hasGiftsInIntervals) {
              showToaster('error', 'Выберите хотя бы один подарок для одного из интервалов');
              loading.value = false;
              return;
            }
          } else if (discount.value.type === 'birthday') {
            // Для birthday проверяем, есть ли хотя бы одно уведомление
            if (birthdayNotifications.value.length === 0) {
              showToaster('error', 'Добавьте хотя бы одно push-уведомление');
              loading.value = false;
              return;
            }
            // Проверяем, что все уведомления имеют заголовок и текст
            const invalidNotification = birthdayNotifications.value.find(n => !n.title?.trim() || !n.body?.trim());
            if (invalidNotification) {
              showToaster('error', 'Заполните заголовок и текст для всех уведомлений');
              loading.value = false;
              return;
            }
          } else if (selectedGiftIds.value.length === 0) {
            // Для других типов проверяем selectedGiftIds
            showToaster('error', 'Выберите хотя бы один подарок');
            loading.value = false;
            return;
          }

          // Формируем settings в зависимости от типа акции
          let settings: any = {};
          if (discount.value.type === 'single_purchase') {
            settings.min_purchase_amount = discount.value.price || 0;
          } else if (discount.value.type === 'birthday') {
            // Сохраняем настройки push-уведомлений
            settings.birthday_notifications = birthdayNotifications.value.map(n => ({
              id: n.id,
              days_before: n.days_before,
              send_time: n.send_time,
              title: n.title,
              body: n.body
            }));
          } else if (discount.value.type === 'friend_discount') {
            // Настройки реферальной программы
            settings.referrer_bonus_percent = discount.value.referrerBonusPercent || 2;
            settings.referrer_max_purchases = discount.value.referrerMaxPurchases || 3;
            settings.referrer_high_discount_threshold = discount.value.referrerHighDiscountThreshold || 30;
            settings.new_user_discount_percent = discount.value.newUserDiscountPercent || 10;
            settings.new_user_bonus_percent = discount.value.newUserBonusPercent || 5;
            settings.new_user_bonus_purchases = discount.value.newUserBonusPurchases || 1;
            // Добавляем интервалы с подарками
            settings.purchase_intervals = purchaseIntervals.value.map(interval => ({
              min_amount: interval.minAmount,
              max_amount: interval.maxAmount,
              gift_ids: interval.giftIds
            }));
          }

          payload = {
            type: discount.value.type,
            settings: settings,
            start_date: discount.value.dates?.[0] ? formattedDate(new Date(discount.value.dates[0])) : null,
            end_date: discount.value.dates?.[1] ? formattedDate(new Date(discount.value.dates[1])) : null,
            name: discount.value.name,
            description: discount.value.description,
          };

          // Добавляем настройки лотереи если это date_based
          if (discount.value.type === 'date_based') {
            payload.push_title = discount.value.push_title || null;
            payload.push_text = discount.value.push_text || null;
            payload.push_send_at = formattedDateTime(discount.value.push_send_at);
            payload.modal_title = discount.value.modal_title || null;
            payload.modal_text = discount.value.modal_text || null;
            payload.modal_button_text = discount.value.modal_button_text || null;
            // Отправляем изображение только если это base64 (новое изображение)
            if (discount.value.modal_image && discount.value.modal_image.startsWith('data:')) {
              payload.modal_image = discount.value.modal_image;
            }
          }

          // Добавляем подарки только если они выбраны (для типов кроме friend_discount)
          if (discount.value.type !== 'friend_discount' && selectedGiftIds.value.length > 0) {
            payload.gift_ids = selectedGiftIds.value;
          }
        }
        if (which.value === 'prizes') {
          console.log('[Save] Gift catalog image:', giftCatalog.value.image?.substring(0, 50) + '...');
          console.log('[Save] Is base64:', giftCatalog.value.image?.startsWith('data:'));
          console.log('[Save] Is URL:', giftCatalog.value.image?.startsWith('http'));
          
          // Проверяем, что есть изображение
          if (!giftCatalog.value.image) {
            showToaster('error', 'Загрузите изображение подарка');
            loading.value = false;
            return;
          }
          
          payload = {
            name: giftCatalog.value.name,
            description: giftCatalog.value.description,
          };
          
          // Отправляем image только если это base64 (новое изображение)
          // Если это URL (старое изображение), не отправляем - бэкенд оставит старое
          if (giftCatalog.value.image.startsWith('data:')) {
            payload.image = giftCatalog.value.image;
            console.log('[Save] Sending new image (base64)');
          } else if (id.value === 'new') {
            // Для нового подарка изображение обязательно должно быть base64
            showToaster('error', 'Ошибка загрузки изображения. Попробуйте снова');
            loading.value = false;
            return;
          } else {
            console.log('[Save] Keeping old image (not sending)');
          }
          
          console.log('[Save] Final payload:', { ...payload, image: payload.image ? 'base64...' : 'not set' });
        }
        const currentApi = api[which.value] as { add: (data: any) => Promise<any>; update: (id: number, data: any) => Promise<any> };
        const response =
          id.value === 'new'
            ? await currentApi.add(payload)
            : await currentApi.update(id.value as number, payload);
        if (response?.message) {
          showToaster('success', String(response.message));
          // Переходим на список с сохранением текущего таба
          await router.push({ name: 'adds', query: { tab: which.value } });
        }
      } catch (err) {
        console.error(err);
      } finally {
        loading.value = false;
      }
    });
  },
  500,
  { maxWait: 3000 }
);

const get = async () => {
  try {
    if (id.value !== 'new') {
      const currentApi = api[which.value] as { get: (id: number) => Promise<any> };
      const response = (await currentApi.get(id.value as number)) as Api.AxiosResponse<any>;
      switch (which.value) {
        case 'discounts': {
          const data = response.data || response;
          discount.value.name = data.name;
          discount.value.description = data.description;
          discount.value.city = data.city;
          discount.value.is_active = !!data.is_active;
          discount.value.expired_at = data.expired_at;
          discount.value.type = data.type;
          
          // Загрузка настроек в зависимости от типа
          if (data.settings) {
            const settings = typeof data.settings === 'string' ? JSON.parse(data.settings) : data.settings;
            
            if (data.type === 'single_purchase' || data.type === 'accumulation') {
              discount.value.price = settings.min_purchase_amount || 0;
            } else if (data.type === 'birthday') {
              // Загружаем настройки push-уведомлений
              if (settings.birthday_notifications && Array.isArray(settings.birthday_notifications)) {
                birthdayNotifications.value = settings.birthday_notifications.map((n: any) => ({
                  id: n.id || `notif-${Date.now()}-${Math.random()}`,
                  days_before: n.days_before ?? 2,
                  send_time: n.send_time || '10:00',
                  title: n.title || 'С днем рождения! 🎂',
                  body: n.body || 'Поздравляем с наступающим днем рождения и дарим вам скидку -30% на все покупки, скидка активна 5 дней'
                }));
              }
            } else if (data.type === 'friend_discount') {
              // Настройки реферальной программы
              discount.value.referrerBonusPercent = settings.referrer_bonus_percent || 2;
              discount.value.referrerMaxPurchases = settings.referrer_max_purchases || 3;
              discount.value.referrerHighDiscountThreshold = settings.referrer_high_discount_threshold || 30;
              discount.value.newUserDiscountPercent = settings.new_user_discount_percent || 10;
              discount.value.newUserBonusPercent = settings.new_user_bonus_percent || 5;
              discount.value.newUserBonusPurchases = settings.new_user_bonus_purchases || 1;
              
              // Загрузка интервалов с подарками
              if (settings.purchase_intervals && Array.isArray(settings.purchase_intervals)) {
                purchaseIntervals.value = settings.purchase_intervals.map((interval: any, idx: number) => ({
                  id: `interval-${idx + 1}`,
                  minAmount: interval.min_amount || 100000,
                  maxAmount: interval.max_amount,
                  giftIds: interval.gift_ids || []
                }));
                // Выбираем первый интервал
                if (purchaseIntervals.value.length > 0) {
                  selectedIntervalId.value = purchaseIntervals.value[0].id;
                }
              }
            }
          }
          
          // Загрузка настроек лотереи (date_based)
          if (data.type === 'date_based') {
            discount.value.push_title = data.push_title || '';
            discount.value.push_text = data.push_text || '';
            discount.value.push_send_at = data.push_send_at || null;
            discount.value.modal_title = data.modal_title || '';
            discount.value.modal_text = data.modal_text || '';
            discount.value.modal_button_text = data.modal_button_text || '';
            // Для изображения формируем полный URL если есть
            if (data.modal_image) {
              discount.value.modal_image = data.modal_image.startsWith('http') 
                ? data.modal_image 
                : `${useRuntimeConfig().public.s3Url}/${data.modal_image}`;
            }
          }
          
          // Загрузка выбранных подарков из каталога
          if (data.gifts) {
            selectedGiftIds.value = data.gifts
              .filter((gift: any) => gift.gift_catalog_id)
              .map((gift: any) => gift.gift_catalog_id);
          }
          
          // Обработка дат
          if (data.start_date && data.end_date) {
            discount.value.dates = [data.start_date, data.end_date];
          }
          
          // Маппинг старого типа accumulation на новый
          if (data.type === 'accumulation') {
            discount.value.type = 'single_purchase';
          }
          
          return;
        }
        case 'prizes': {
          const data = response.data || response;
          giftCatalog.value.name = data.name || '';
          giftCatalog.value.description = data.description || '';
          giftCatalog.value.image = data.image_url || data.image || '';
          return;
        }
      }
    }
  } catch (err) {
    console.error(err);
  }
};

const getData = async () => {
  // Функция зарезервирована для загрузки дополнительных данных при необходимости
};

const convertToBase64 = (file: File): Promise<string> => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result as string);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
};

const base64ToFile = (base64: string, filename = 'photo.jpg'): File => {
  const arr = base64.split(',');
  const mime = arr[0].match(/:(.*?);/)![1];
  const bstr = atob(arr[1]);
  let n = bstr.length;
  const u8arr = new Uint8Array(n);
  while (n--) u8arr[n] = bstr.charCodeAt(n);
  return new File([u8arr], filename, { type: mime });
};

const formatBytes = (bytes: number): string => {
  if (bytes === 0) return '0 Б';
  const k = 1024;
  const sizes = ['Б', 'КБ', 'МБ', 'ГБ'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};


// Конвертация изображения через Canvas (для WebP и других форматов)
const convertImageViaCanvas = (file: File, maxWidth = 800, maxHeight = 800, quality = 0.9): Promise<string> => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      const img = new Image();
      img.onload = () => {
        // Рассчитываем новые размеры
        let { width, height } = img;
        if (width > maxWidth) {
          height = (height * maxWidth) / width;
          width = maxWidth;
        }
        if (height > maxHeight) {
          width = (width * maxHeight) / height;
          height = maxHeight;
        }
        
        // Создаём canvas и рисуем изображение
        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        if (!ctx) {
          reject(new Error('Canvas context not available'));
          return;
        }
        ctx.drawImage(img, 0, 0, width, height);
        
        // Конвертируем в JPEG (универсальный формат)
        const base64 = canvas.toDataURL('image/jpeg', quality);
        resolve(base64);
      };
      img.onerror = () => reject(new Error('Failed to load image'));
      img.src = e.target?.result as string;
    };
    reader.onerror = () => reject(new Error('Failed to read file'));
    reader.readAsDataURL(file);
  });
};

// Для каталога подарков
const handleGiftPhotoUpload = async (src: string | File) => {
  console.log('[Gift Upload] Received:', typeof src === 'string' ? 'base64 string' : 'File object');
  
  try {
    const file = typeof src === 'string' ? base64ToFile(src) : src;
    console.log('[Gift Upload] File:', file.name, file.type, file.size, 'bytes');
    
    // Проверяем, поддерживает ли Compressor этот формат
    const supportedByCompressor = ['image/jpeg', 'image/png', 'image/jpg'].includes(file.type);
    
    if (supportedByCompressor) {
      // Используем Compressor для JPEG/PNG
      new Compressor(file, {
        quality: 0.9,
        maxWidth: 800,
        maxHeight: 800,
        success: async (compressed: File) => {
          console.log('[Gift Upload] Compressed:', compressed.size, 'bytes');
          const base64 = await convertToBase64(compressed);
          console.log('[Gift Upload] Base64 set, length:', base64.length);
          giftCatalog.value.image = base64;
        },
        error(err) {
          console.error('[Gift Upload] Compression error:', err);
          showToaster('error', 'Ошибка сжатия изображения');
        },
      });
    } else {
      // Для WebP и других форматов - используем Canvas
      console.log('[Gift Upload] Using Canvas conversion for:', file.type);
      const base64 = await convertImageViaCanvas(file);
      console.log('[Gift Upload] Canvas converted, length:', base64.length);
      giftCatalog.value.image = base64;
    }
  } catch (err) {
    console.error('[Gift Upload] Error:', err);
    showToaster('error', 'Ошибка обработки изображения');
  }
};

// Загрузка списка подарков из каталога
const loadGiftCatalog = async () => {
  try {
    const response = await api.prizes.getActive();
    availableGifts.value = Array.isArray(response) ? response : (response as any).data || [];
  } catch (err) {
    console.error('Error loading gift catalog:', err);
  }
};

// ===== Модальное окно добавления подарка =====
const openAddGiftModal = () => {
  newGiftData.value = { name: '', description: '', image: '' };
  newGiftImage.value = null;
  showAddGiftModal.value = true;
};

const closeAddGiftModal = () => {
  showAddGiftModal.value = false;
  newGiftData.value = { name: '', description: '', image: '' };
  newGiftImage.value = null;
};

const handleNewGiftPhotoUpload = async (src: string | File) => {
  try {
    const file = typeof src === 'string' ? base64ToFile(src) : src;
    const supportedByCompressor = ['image/jpeg', 'image/png', 'image/jpg'].includes(file.type);
    
    if (supportedByCompressor) {
      new Compressor(file, {
        quality: 0.9,
        maxWidth: 800,
        maxHeight: 800,
        success: async (compressed: File) => {
          const base64 = await convertToBase64(compressed);
          newGiftData.value.image = base64;
        },
        error(err) {
          console.error('[New Gift Upload] Compression error:', err);
          showToaster('error', 'Ошибка сжатия изображения');
        },
      });
    } else {
      const base64 = await convertImageViaCanvas(file);
      newGiftData.value.image = base64;
    }
  } catch (err) {
    console.error('[New Gift Upload] Error:', err);
    showToaster('error', 'Ошибка обработки изображения');
  }
};

// Обработка загрузки изображения модального окна лотереи
const handleModalImageUpload = async (event: Event) => {
  const input = event.target as HTMLInputElement;
  if (!input.files || input.files.length === 0) return;

  const file = input.files[0];
  if (!file.type.startsWith('image/')) {
    showToaster('error', 'Пожалуйста, выберите изображение');
    return;
  }

  try {
    const supportedByCompressor = ['image/jpeg', 'image/png', 'image/jpg'].includes(file.type);
    
    if (supportedByCompressor) {
      new Compressor(file, {
        quality: 0.9,
        maxWidth: 800,
        maxHeight: 800,
        success: async (compressed: File) => {
          const base64 = await convertToBase64(compressed);
          discount.value.modal_image = base64;
        },
        error(err) {
          console.error('[Modal Image Upload] Compression error:', err);
          showToaster('error', 'Ошибка сжатия изображения');
        },
      });
    } else {
      const base64 = await convertImageViaCanvas(file);
      discount.value.modal_image = base64;
    }
  } catch (err) {
    console.error('[Modal Image Upload] Error:', err);
    showToaster('error', 'Ошибка обработки изображения');
  }
};

const saveNewGift = async () => {
  if (!newGiftData.value.name.trim()) {
    showToaster('error', 'Введите название подарка');
    return;
  }
  
  addGiftLoading.value = true;
  try {
    const payload = {
      name: newGiftData.value.name.trim(),
      description: newGiftData.value.description.trim() || '',
      image: newGiftData.value.image || '',
    };
    
    await api.prizes.add(payload as Api.GiftCatalog.New);
    showToaster('success', 'Подарок успешно добавлен');
    closeAddGiftModal();
    // Перезагружаем список подарков
    await loadGiftCatalog();
  } catch (err) {
    console.error('[Save Gift] Error:', err);
    showToaster('error', 'Ошибка при сохранении подарка');
  } finally {
    addGiftLoading.value = false;
  }
};

// Переключение выбора подарка
const toggleGiftSelection = (giftId: number) => {
  if (discount.value.type === 'friend_discount' && currentInterval.value) {
    const index = currentInterval.value.giftIds.indexOf(giftId);
    if (index > -1) {
      currentInterval.value.giftIds.splice(index, 1);
    } else if (currentInterval.value.giftIds.length < 4) {
      currentInterval.value.giftIds.push(giftId);
    }
  } else {
    const index = selectedGiftIds.value.indexOf(giftId);
    if (index > -1) {
      selectedGiftIds.value.splice(index, 1);
    } else if (selectedGiftIds.value.length < 4) {
      selectedGiftIds.value.push(giftId);
    }
  }
};

useHead({
  title: () =>
    `${t('admin.nav.adds')} - ${
      (id.value === 'new' ? 'Добавить ' : 'Редактировать ') +
      t(`admin.adds.${which.value}`)
    }`,
});

onBeforeMount(() => {
  const tab = String(route.params.tab) as AdminEnums.AddsItems;
  if (tab && tab in AdminEnums.AddsItems) {
    if (layoutStore.addsTab !== tab) layoutStore.addsTab = tab;
  } else router.push({ name: 'adds' });
});

// Функция синхронизации позиции sidebar с основным контентом
const syncSidebarPosition = () => {
  if (!sidebarRef.value || !mainContentRef.value) return;
  
  const mainRect = mainContentRef.value.getBoundingClientRect();
  const viewportHeight = window.innerHeight;
  const headerHeight = 80;
  
  // Верхняя граница: либо верх main контента, либо header (что ниже)
  const topBoundary = Math.max(mainRect.top, headerHeight);
  
  // Нижняя граница: низ main контента
  const bottomFromViewport = viewportHeight - mainRect.bottom;
  
  // Если main контент выше viewport - прижимаем к header
  if (mainRect.top < headerHeight) {
    sidebarRef.value.style.top = headerHeight + 'px';
  } else {
    sidebarRef.value.style.top = mainRect.top + 'px';
  }
  
  // Если низ main контента в viewport - прижимаем к нему
  if (mainRect.bottom < viewportHeight) {
    sidebarRef.value.style.bottom = (viewportHeight - mainRect.bottom) + 'px';
  } else {
    sidebarRef.value.style.bottom = '24px';
  }
};

onMounted(async () => {
  // Загружаем каталог подарков если мы на странице акций
  if (which.value === 'discounts') {
    await loadGiftCatalog();
  }
  await Promise.allSettled([getData(), get()]);
  
  // Инициализируем синхронизацию sidebar
  if (which.value === 'discounts') {
    // Первоначальная синхронизация после рендера
    nextTick(() => {
      syncSidebarPosition();
    });
    
    // Слушаем scroll и resize
    window.addEventListener('scroll', syncSidebarPosition, { passive: true });
    window.addEventListener('resize', syncSidebarPosition, { passive: true });
  }
});

onUnmounted(() => {
  window.removeEventListener('scroll', syncSidebarPosition);
  window.removeEventListener('resize', syncSidebarPosition);
});
</script>

<style scoped>
/* ===== ОСНОВНОЙ КОНТЕЙНЕР ===== */
.adds-edit-page {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  color: var(--color-text-primary);
}

@media (min-width: 600px) {
  .adds-edit-page {
    gap: 1.5rem;
  }
}

.adds-edit-page__header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 6px;
  flex-wrap: wrap;
  gap: 0.75rem;
}

@media (max-width: 599px) {
  .adds-edit-page__header {
    flex-direction: column;
    align-items: stretch;
  }
  
  .adds-edit-page__header > :last-child {
    align-self: flex-end;
  }
}

.adds-edit-page__breadcrumbs {
  color: var(--color-text-secondary);
}

.adds-edit-page__breadcrumbs :deep(.v-breadcrumbs-item) {
  color: var(--color-text-secondary);
}

.adds-edit-page__breadcrumbs :deep(.v-icon) {
  color: var(--color-text-muted);
}

.adds-edit-page__form {
  color: var(--color-text-primary);
}

.adds-edit-page__content {
  display: flex;
  flex-direction: column;
  min-height: auto;
  gap: 1rem;
}

@media (min-width: 960px) {
  .adds-edit-page__content {
    flex-direction: row;
    min-height: 350px;
    gap: 1.5rem;
  }
}

.adds-edit-page__sidebar {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  width: 100%;
  order: 2; /* Sidebar справа */
}

@media (min-width: 960px) {
  .adds-edit-page__sidebar {
    position: fixed;
    top: 80px; /* Начальное значение, будет обновляться JS */
    right: 24px;
    bottom: 24px; /* Начальное значение, будет обновляться JS */
    width: 320px;
    max-width: 320px;
    overflow-y: auto;
    z-index: 99; /* Ниже modals и dialogs */
    scrollbar-width: thin;
    scrollbar-color: rgba(139, 195, 74, 0.3) transparent;
    transition: top 0.1s ease-out, bottom 0.1s ease-out;
    pointer-events: auto;
  }

  .adds-edit-page__sidebar::-webkit-scrollbar {
    width: 6px;
  }

  .adds-edit-page__sidebar::-webkit-scrollbar-track {
    background: transparent;
  }

  .adds-edit-page__sidebar::-webkit-scrollbar-thumb {
    background-color: rgba(139, 195, 74, 0.3);
    border-radius: 3px;
  }

  .adds-edit-page__sidebar::-webkit-scrollbar-thumb:hover {
    background-color: rgba(139, 195, 74, 0.5);
  }
}

.adds-edit-page__main {
  width: 100%;
  order: 1; /* Main слева */
}

@media (min-width: 960px) {
  .adds-edit-page__main {
    flex: 1;
    width: auto;
    margin-right: 340px; /* Отступ для fixed sidebar */
  }
}

/* ===== КАТАЛОГ ПОДАРКОВ ===== */
.gift-catalog {
  width: 100%;
}

.gift-catalog__title {
  margin-bottom: 1rem;
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.gift-catalog__subtitle {
  margin-bottom: 0.5rem;
  font-size: 0.875rem;
  color: var(--color-text-secondary);
}

.gift-catalog__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: 1rem 0;
  color: var(--color-text-muted);
}

.gift-catalog__empty-icon {
  font-size: 2.5rem;
  margin-bottom: 0.5rem;
}

.gift-catalog__link {
  color: var(--color-accent);
  text-decoration: underline;
}

.gift-catalog__list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  max-height: 400px;
  overflow-y: auto;
  scrollbar-width: thin;
  scrollbar-color: rgba(155, 155, 155, 0.5) transparent;
}

.gift-catalog__list::-webkit-scrollbar {
  width: 6px;
}

.gift-catalog__list::-webkit-scrollbar-track {
  background: transparent;
}

.gift-catalog__list::-webkit-scrollbar-thumb {
  background-color: rgba(155, 155, 155, 0.5);
  border-radius: 3px;
}

.gift-catalog__item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: all 0.2s ease;
  border: 2px solid transparent;
  background-color: var(--color-bg-tertiary);
}

.gift-catalog__item:hover {
  background-color: var(--color-bg-hover);
}

.gift-catalog__item--selected {
  border-color: var(--color-accent);
  background-color: rgba(152, 179, 93, 0.15);
}

.gift-catalog__item-image {
  width: 3rem;
  height: 3rem;
  border-radius: 0.5rem;
  object-fit: cover;
}

.gift-catalog__item-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 3rem;
  height: 3rem;
  border-radius: 0.5rem;
  background-color: var(--color-bg-secondary);
  color: var(--color-text-muted);
}

.gift-catalog__item-info {
  flex: 1;
  min-width: 0;
}

.gift-catalog__item-name {
  font-weight: 500;
  color: var(--color-text-primary);
}

.gift-catalog__item-desc {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.gift-catalog__counter {
  margin-top: 0.75rem;
  font-size: 0.875rem;
  color: var(--color-text-secondary);
}

.gift-catalog__counter span {
  font-weight: 600;
  color: var(--color-text-primary);
}

.gift-catalog__add-new {
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid var(--color-border);
}

.gift-catalog__add-link {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--color-accent);
  transition: opacity 0.2s ease;
}

.gift-catalog__add-link:hover {
  opacity: 0.8;
}

/* ===== ФОРМА АКЦИИ ===== */
.discount-form {
  width: 100%;
}

.discount-form__title {
  margin-bottom: 0.5rem;
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.discount-form__fields {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
  gap: 0.25rem;
}

.discount-form__label {
  font-size: 0.875rem;
  color: var(--color-text-primary);
}

.discount-form__label--mt {
  margin-top: 0.75rem;
}

/* ===== ФОРМА ИЗОБРАЖЕНИЯ ПОДАРКА ===== */
.prize-image-form {
  height: fit-content;
  width: 100%;
}

@media (min-width: 960px) {
  .prize-image-form {
    width: 33.333%;
    min-width: 250px;
    max-width: 350px;
  }
}

.prize-image-form__title {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.5rem;
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.prize-image-form__remove-btn {
  color: var(--color-text-muted);
}

.prize-image-form__remove-icon {
  cursor: pointer;
  font-size: 1.875rem;
}

.prize-image-form__content {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
}

.prize-image-form__upload {
  min-height: 230px;
}

.prize-image-form__icon-bg {
  fill: var(--color-accent);
}

.prize-image-form__upload-text {
  margin-top: 1rem;
  text-align: center;
  font-size: 0.875rem;
  color: var(--color-text-muted);
}

.prize-image-form__preview {
  display: flex;
  flex-grow: 1;
  align-items: center;
  justify-content: center;
}

.prize-image-form__image {
  border-radius: 0.5rem;
  max-height: 300px;
}

/* ===== ФОРМА ИНФОРМАЦИИ О ПОДАРКЕ ===== */
.prize-info-form {
  width: 100%;
}

@media (min-width: 960px) {
  .prize-info-form {
    flex: 1;
    width: auto;
  }
}

.prize-info-form__title {
  margin-bottom: 0.5rem;
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.prize-info-form__fields {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
  gap: 0.25rem;
}

.prize-info-form__label {
  font-size: 0.875rem;
  color: var(--color-text-primary);
}

/* ===== CHECKBOX СТИЛИ ===== */
:deep(.gift-catalog__item .v-checkbox .v-selection-control__input) {
  color: var(--color-accent);
}

:deep(.v-checkbox .v-selection-control__wrapper) {
  color: var(--color-text-primary);
}

/* ===== ИНПУТЫ ===== */
:deep(.discount-form__input .v-field),
:deep(.prize-info-form__input .v-field) {
  background-color: var(--color-bg-input) !important;
}

:deep(.discount-form__input .v-field__input),
:deep(.prize-info-form__input .v-field__input) {
  color: var(--color-text-primary) !important;
}

:deep(.discount-form__input .v-field__outline),
:deep(.prize-info-form__input .v-field__outline) {
  color: var(--color-border) !important;
}

:deep(.discount-form__input .v-label),
:deep(.prize-info-form__input .v-label) {
  color: var(--color-text-secondary) !important;
}

/* ===== НАСТРОЙКИ ТИПОВ АКЦИЙ ===== */
.discount-form__type-settings {
  margin-top: 0.5rem;
  padding: 1rem;
  background-color: var(--color-bg-tertiary);
  border-radius: 0.75rem;
  border: 1px solid var(--color-border);
}

.discount-form__hint {
  margin-top: 0.5rem;
  font-size: 0.8125rem;
  color: var(--color-text-muted);
  font-style: italic;
}

/* ===== СПЕЦИФИКА ДЛЯ ДР ===== */
.discount-form__birthday-alert {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  padding: 0.875rem;
  margin-bottom: 1rem;
  background: linear-gradient(135deg, rgba(152, 179, 93, 0.15) 0%, rgba(152, 179, 93, 0.08) 100%);
  border-radius: 0.5rem;
  border: 1px solid rgba(152, 179, 93, 0.3);
}

.discount-form__birthday-icon {
  flex-shrink: 0;
  font-size: 1.25rem;
  color: var(--color-accent);
}

.discount-form__birthday-alert span {
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
  line-height: 1.5;
}

/* ===== СПЕЦИФИКА ДЛЯ ЛОТЕРЕИ ===== */
.discount-form__lottery {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.discount-form__divider {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin: 1.5rem 0 0.5rem;
  font-weight: 600;
  color: var(--color-text-primary);
  font-size: 0.9375rem;
}

.discount-form__divider::before,
.discount-form__divider::after {
  content: '';
  flex: 1;
  height: 1px;
  background: linear-gradient(to right, transparent, var(--color-border), transparent);
}

.discount-form__divider span {
  padding: 0 0.5rem;
  background: var(--color-bg-primary);
}

.discount-form__image-upload {
  margin-top: 0.25rem;
}

.discount-form__image-preview {
  position: relative;
  display: inline-block;
  border-radius: 0.75rem;
  overflow: hidden;
  border: 2px solid var(--color-border);
}

.discount-form__image-preview img {
  max-width: 200px;
  max-height: 200px;
  object-fit: cover;
  display: block;
}

.discount-form__image-remove {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
}

/* ===== СПЕЦИФИКА ДЛЯ РЕФЕРАЛЬНОЙ ПРОГРАММЫ ===== */
.discount-form__referral {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.discount-form__referral-alert {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  padding: 0.875rem;
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.15) 0%, rgba(59, 130, 246, 0.08) 100%);
  border-radius: 0.5rem;
  border: 1px solid rgba(59, 130, 246, 0.3);
}

.discount-form__referral-icon {
  flex-shrink: 0;
  font-size: 1.25rem;
  color: #3B82F6;
}

.discount-form__referral-alert span {
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
  line-height: 1.5;
}

.discount-form__section {
  padding: 1rem;
  background: var(--color-bg-secondary);
  border-radius: 0.75rem;
  border: 1px solid var(--color-border);
}

.discount-form__section--highlight {
  background: linear-gradient(135deg, rgba(245, 158, 11, 0.08) 0%, rgba(245, 158, 11, 0.03) 100%);
  border-color: rgba(245, 158, 11, 0.3);
}

.discount-form__section-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.9375rem;
  font-weight: 600;
  color: var(--color-text-primary);
  margin: 0 0 0.75rem 0;
}

.discount-form__section-title :deep(.iconify) {
  font-size: 1.125rem;
  color: var(--color-accent);
}

.discount-form__row {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

@media (min-width: 600px) {
  .discount-form__row {
    flex-direction: row;
    gap: 1rem;
  }
}

.discount-form__col {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.discount-form__preview {
  padding: 1rem;
  background: var(--color-bg-secondary);
  border-radius: 0.75rem;
  border: 2px dashed var(--color-border);
}

.discount-form__preview h5 {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text-secondary);
  margin: 0 0 0.75rem 0;
}

.discount-form__preview ul {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.discount-form__preview li {
  font-size: 0.8125rem;
  color: var(--color-text-primary);
  line-height: 1.4;
}

.discount-form__hint--info {
  color: #F59E0B;
  font-style: normal;
  margin-top: -0.3rem;
}

.discount-form__locked-badge {
  display: inline-block;
  margin-left: 0.5rem;
  font-size: 0.75rem;
  color: #8BC34A;
  font-weight: 500;
  background: rgba(139, 195, 74, 0.1);
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
}

.discount-form__input--disabled {
  opacity: 0.6;
}

/* ===== ИНТЕРВАЛЫ СУММ ===== */
.discount-form__intervals {
  margin-top: 1rem;
}

.discount-form__intervals-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin: 0.75rem 0;
}

.discount-form__interval-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem;
  background: var(--color-bg-secondary);
  border: 2px solid var(--color-border);
  border-radius: 0.5rem;
  cursor: pointer;
  transition: all 0.2s;
}

.discount-form__interval-item:hover {
  border-color: var(--color-primary);
  background: rgba(139, 195, 74, 0.05);
}

.discount-form__interval-item--active {
  border-color: #8BC34A;
  background: rgba(139, 195, 74, 0.1);
  font-weight: 600;
}

.discount-form__interval-inputs {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex: 1;
}

.discount-form__interval-input-group {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.discount-form__interval-label {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  min-width: 24px;
}

.discount-form__interval-input {
  max-width: 140px;
}

.discount-form__interval-input :deep(.v-field__input) {
  font-size: 0.875rem;
  padding: 0.25rem 0.5rem;
}

.discount-form__interval-infinity {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.25rem;
  min-width: 140px;
  height: 40px;
  background: rgba(139, 195, 74, 0.1);
  border: 1px dashed rgba(139, 195, 74, 0.5);
  border-radius: 0.5rem;
  color: #8BC34A;
  font-size: 1.25rem;
  font-weight: 600;
}


.discount-form__interval-badges {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-shrink: 0;
}

.discount-form__interval-badge {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
  background: var(--color-bg-primary);
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
}

.discount-form__btn-add-interval {
  margin-top: 0.5rem;
  margin-bottom: 1.5rem;
  width: 100%;
}

.discount-form__interval-delete-btn :deep(.iconify) {
  font-size: 1.25rem;
}

.gift-catalog__subtitle-small {
  margin: 0.5rem 0 0.75rem 0;
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

/* ===== БЕЙДЖИКИ ИНТЕРВАЛОВ В КАТАЛОГЕ ===== */
.gift-catalog__interval-badges {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin: 0.75rem 0 1rem 0;
}

.gift-catalog__interval-badge-btn {
  padding: 0.5rem 0.75rem;
  font-size: 0.75rem;
  font-weight: 500;
  color: var(--color-text-secondary);
  background: var(--color-bg-secondary);
  border: 1px solid var(--color-border);
  border-radius: 0.375rem;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.gift-catalog__interval-badge-btn:hover {
  border-color: #8BC34A;
  background: rgba(139, 195, 74, 0.05);
}

.gift-catalog__interval-badge-btn--active {
  background: rgba(139, 195, 74, 0.2);
  border-color: #8BC34A;
  color: #8BC34A;
  font-weight: 600;
}

/* ===== ПЕРИОД И СТАТУС ===== */
.discount-form__toggle-row {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.75rem 1rem;
  background: linear-gradient(135deg, rgba(139, 195, 74, 0.08) 0%, rgba(139, 195, 74, 0.04) 100%);
  border: 1.5px solid rgba(139, 195, 74, 0.25);
  border-radius: 0.5rem;
  margin-bottom: 1.5rem;
}

.discount-form__toggle-wrapper {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex: 1;
}

.discount-form__switch {
  margin: 0 !important;
  padding: 0 !important;
  height: 32px;
  display: flex;
  align-items: center;
  flex-shrink: 0;
}

.discount-form__switch :deep(.v-input__control) {
  height: 100%;
  display: flex;
  align-items: center;
}

.discount-form__switch :deep(.v-selection-control) {
  min-height: 32px !important;
}

.discount-form__switch :deep(.v-selection-control__wrapper) {
  width: 51px !important;
  height: 31px !important;
  position: relative !important;
}

.discount-form__switch :deep(.v-selection-control__input) {
  width: 51px !important;
  height: 31px !important;
  position: absolute !important;
  left: 0 !important;
  top: 0 !important;
  transform: none !important;
}

.discount-form__switch :deep(.v-switch__track) {
  background: #78788029 !important;
  opacity: 1 !important;
  width: 51px !important;
  height: 31px !important;
  border-radius: 15.5px !important;
  position: absolute !important;
  left: 0 !important;
  top: 0 !important;
}

.discount-form__switch :deep(.v-selection-control--dirty .v-switch__track) {
  background: #8BC34A !important;
}

.discount-form__switch :deep(.v-switch__thumb) {
  width: 27px !important;
  height: 27px !important;
  background: #FFFFFF !important;
  box-shadow: 0 3px 8px rgba(0, 0, 0, 0.15), 0 1px 1px rgba(0, 0, 0, 0.16) !important;
  position: absolute !important;
  left: 2px !important;
  top: 2px !important;
  transform: none !important;
  transition: left 0.2s cubic-bezier(0.4, 0, 0.2, 1) !important;
  border-radius: 50% !important;
}

.discount-form__switch :deep(.v-selection-control--dirty .v-switch__thumb) {
  left: 22px !important;
  transform: none !important;
}

.discount-form__switch.v-input--disabled :deep(.v-switch__track) {
  background: rgba(120, 120, 128, 0.16) !important;
}

.discount-form__toggle-label {
  font-size: 0.9rem;
  color: var(--color-text-primary);
  font-weight: 600;
  white-space: nowrap;
  line-height: 32px;
  margin: 0;
}

.discount-form__period-buttons {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.discount-form__period-buttons .v-btn {
  font-size: 0.8125rem;
  text-transform: none;
  letter-spacing: 0;
}

/* ===== МОДАЛЬНОЕ ОКНО ДОБАВЛЕНИЯ ПОДАРКА ===== */
.add-gift-modal {
  border-radius: 1rem !important;
  overflow: hidden;
}

.add-gift-modal__title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 1rem 1.25rem;
  font-size: 1.125rem;
  font-weight: 600;
  background: linear-gradient(135deg, rgba(139, 195, 74, 0.12) 0%, rgba(139, 195, 74, 0.05) 100%);
  border-bottom: 1px solid rgba(139, 195, 74, 0.2);
}

.add-gift-modal__title-icon {
  font-size: 1.5rem;
  color: #8BC34A;
}

.add-gift-modal__close {
  margin-left: auto;
  opacity: 0.7;
}

.add-gift-modal__close:hover {
  opacity: 1;
}

.add-gift-modal__content {
  padding: 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.add-gift-modal__image-section {
  display: flex;
  justify-content: center;
}

.add-gift-modal__upload {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  width: 120px;
  height: 120px;
  border: 2px dashed rgba(139, 195, 74, 0.4);
  border-radius: 0.75rem;
  background: rgba(139, 195, 74, 0.05);
  cursor: pointer;
  transition: all 0.2s ease;
}

.add-gift-modal__upload:hover {
  border-color: #8BC34A;
  background: rgba(139, 195, 74, 0.1);
}

.add-gift-modal__upload-icon {
  font-size: 2rem;
  color: #8BC34A;
}

.add-gift-modal__upload-text {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  text-align: center;
}

.add-gift-modal__preview {
  position: relative;
  width: 120px;
  height: 120px;
}

.add-gift-modal__preview-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 0.75rem;
  border: 2px solid rgba(139, 195, 74, 0.3);
}

.add-gift-modal__preview-remove {
  position: absolute;
  top: -8px;
  right: -8px;
}

.add-gift-modal__input {
  margin-bottom: 0;
}

.add-gift-modal__actions {
  padding: 0.75rem 1.25rem 1.25rem;
  justify-content: flex-end;
  gap: 0.5rem;
}

.add-gift-modal__actions .v-btn {
  text-transform: none;
  letter-spacing: 0;
}

.gift-catalog__link {
  background: none;
  border: none;
  cursor: pointer;
  font-family: inherit;
  font-size: inherit;
}

.gift-catalog__add-link {
  background: none;
  border: none;
  cursor: pointer;
  font-family: inherit;
}

/* ===== BIRTHDAY NOTIFICATIONS ===== */
/* Сохраняем ту же ширину основного контента даже без sidebar */

.discount-form__notifications-section {
  margin-top: 0.5rem;
}

.discount-form__notifications-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  flex-wrap: wrap;
  gap: 0.75rem;
}

.discount-form__notifications-header h4 {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text-primary);
  margin: 0;
}

.discount-form__notifications-header h4 :deep(.iconify) {
  font-size: 1.25rem;
  color: #EC4899;
}

.discount-form__notifications-empty {
  text-align: center;
  padding: 2rem;
  color: var(--color-text-muted);
  font-style: italic;
  background: var(--color-bg-secondary);
  border-radius: 0.75rem;
  border: 2px dashed var(--color-border);
}

.discount-form__notifications-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.discount-form__notification-card {
  padding: 1rem;
  background: var(--color-bg-secondary);
  border-radius: 0.75rem;
  border: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  transition: all 0.3s ease;
}

.discount-form__notification-card:hover {
  border-color: #EC4899;
  box-shadow: 0 4px 12px rgba(236, 72, 153, 0.1);
}

.discount-form__notification-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.discount-form__notification-number {
  font-weight: 600;
  color: #EC4899;
  font-size: 0.875rem;
}

.discount-form__notification-timing {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

@media (max-width: 599px) {
  .discount-form__notification-timing {
    grid-template-columns: 1fr;
  }
}

.discount-form__notification-timing-field {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.discount-form__notification-preview {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem;
  background: linear-gradient(135deg, rgba(236, 72, 153, 0.1) 0%, rgba(236, 72, 153, 0.05) 100%);
  border-radius: 0.5rem;
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
  margin-top: 0.25rem;
}

.discount-form__notification-preview :deep(.iconify) {
  font-size: 1rem;
  color: #EC4899;
}

.discount-form__notification-preview strong {
  color: #EC4899;
}

/* Animations for notifications */
.notification-item-enter-active,
.notification-item-leave-active {
  transition: all 0.3s ease;
}

.notification-item-enter-from {
  opacity: 0;
  transform: translateY(-10px);
}

.notification-item-leave-to {
  opacity: 0;
  transform: translateX(20px);
}

.notification-item-move {
  transition: transform 0.3s ease;
}
</style>
