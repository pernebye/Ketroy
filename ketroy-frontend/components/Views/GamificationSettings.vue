<template>
  <div class="gamification">
    <!-- Заголовок -->
    <div class="gamification__header">
      <div class="gamification__title-section">
        <h2 class="gamification__title">
          <Icon name="mdi:trophy-variant" class="gamification__title-icon" />
          Система уровней лояльности
        </h2>
        <p class="gamification__subtitle">
          Настройте уровни и награды для геймификации программы лояльности
        </p>
      </div>
      <v-btn
        color="primary"
        variant="flat"
        rounded="lg"
        @click="openCreateDialog"
        class="gamification__add-btn"
      >
        <Icon name="mdi:plus" class="gamification__add-icon" />
        Добавить уровень
      </v-btn>
    </div>

    <!-- Загрузка -->
    <div v-if="loading" class="gamification__loading">
      <v-progress-circular indeterminate color="var(--color-accent)" :size="48" :width="4" />
      <span>Загрузка уровней...</span>
    </div>

    <!-- Пустое состояние -->
    <div v-else-if="levels.length === 0" class="gamification__empty">
      <div class="gamification__empty-icon">
        <Icon name="mdi:trophy-outline" />
      </div>
      <h3 class="gamification__empty-title">Уровни не настроены</h3>
      <p class="gamification__empty-text">
        Создайте первый уровень лояльности, чтобы начать геймификацию программы
      </p>
      <v-btn color="primary" variant="flat" rounded="lg" @click="openCreateDialog">
        <Icon name="mdi:plus" />
        Создать первый уровень
      </v-btn>
    </div>

    <!-- Список уровней -->
    <div v-else class="gamification__levels">
      <TransitionGroup name="level-list" tag="div" class="gamification__levels-grid">
        <div
          v-for="(level, index) in sortedLevels"
          :key="level.id"
          class="gamification__level"
          :style="{ '--level-color': level.color || '#98B35D' }"
        >
          <!-- Шапка уровня -->
          <div class="gamification__level-header">
            <div class="gamification__level-badge">
              <span class="gamification__level-icon">{{ level.icon || '🏆' }}</span>
              <span class="gamification__level-order">#{{ index + 1 }}</span>
            </div>
            <div class="gamification__level-info">
              <h3 class="gamification__level-name">{{ level.name }}</h3>
              <p class="gamification__level-threshold">
                от {{ formatNumber(level.min_purchase_amount) }} ₸
              </p>
            </div>
            <div class="gamification__level-actions">
              <v-btn icon variant="text" size="small" @click="editLevel(level)">
                <Icon name="mdi:pencil" />
              </v-btn>
              <v-btn icon variant="text" size="small" color="error" @click="confirmDelete(level)">
                <Icon name="mdi:delete" />
              </v-btn>
            </div>
          </div>

          <!-- Награды -->
          <div class="gamification__level-rewards">
            <p class="gamification__rewards-title">
              <Icon name="mdi:gift" />
              Награды за достижение
            </p>
            <div v-if="level.rewards && level.rewards.length > 0" class="gamification__rewards-list">
              <div
                v-for="reward in level.rewards"
                :key="reward.id"
                class="gamification__reward"
                :class="`gamification__reward--${reward.reward_type}`"
              >
                <div class="gamification__reward-icon">
                  <Icon :name="getRewardIcon(reward.reward_type)" />
                </div>
                <div class="gamification__reward-content">
                  <span class="gamification__reward-type">{{ getRewardTypeName(reward.reward_type) }}</span>
                  <span class="gamification__reward-value">{{ getRewardValue(reward) }}</span>
                </div>
              </div>
            </div>
            <p v-else class="gamification__no-rewards">
              <Icon name="mdi:information-outline" />
              Награды не настроены
            </p>
          </div>

          <!-- Статус -->
          <div class="gamification__level-footer">
            <v-chip
              :color="level.is_active ? 'success' : 'error'"
              size="small"
              variant="tonal"
            >
              {{ level.is_active ? 'Активен' : 'Неактивен' }}
            </v-chip>
          </div>
        </div>
      </TransitionGroup>
    </div>

    <!-- Диалог создания/редактирования уровня -->
    <v-dialog v-model="showDialog" max-width="700" persistent scrollable>
      <v-card rounded="xl" class="gamification__dialog">
        <v-card-title class="gamification__dialog-title">
          <Icon :name="editingLevel ? 'mdi:pencil' : 'mdi:plus-circle'" class="gamification__dialog-icon" />
          {{ editingLevel ? 'Редактировать уровень' : 'Создать уровень' }}
        </v-card-title>
        
        <v-card-text class="gamification__dialog-content">
          <v-form ref="formRef" class="gamification__form">
            <!-- Основная информация -->
            <div class="gamification__form-section">
              <p class="gamification__form-section-title">Основная информация</p>
              
              <div class="gamification__form-row">
                <div class="gamification__form-field gamification__form-field--icon">
                  <label class="gamification__label">Иконка</label>
                  <v-menu v-model="showEmojiPicker" location="bottom" offset="10">
                    <template v-slot:activator="{ props }">
                      <v-text-field
                        v-bind="props"
                        v-model="form.icon"
                        variant="outlined"
                        density="compact"
                        placeholder="🏆"
                        rounded="lg"
                        hide-details
                        readonly
                        class="gamification__input gamification__input--icon"
                        style="cursor: pointer;"
                      />
                    </template>
                    <div class="gamification__emoji-picker">
                      <div class="gamification__emoji-grid">
                        <button
                          v-for="emoji in availableEmojis"
                          :key="emoji"
                          class="gamification__emoji-btn"
                          :class="{ 'gamification__emoji-btn--selected': form.icon === emoji }"
                          @click="form.icon = emoji; showEmojiPicker = false"
                        >
                          {{ emoji }}
                        </button>
                      </div>
                    </div>
                  </v-menu>
                </div>
                <div class="gamification__form-field gamification__form-field--name">
                  <label class="gamification__label">Название уровня *</label>
                  <v-text-field
                    v-model="form.name"
                    variant="outlined"
                    density="compact"
                    placeholder="Например: Золото"
                    rounded="lg"
                    :rules="[rules.required]"
                  />
                </div>
              </div>

              <div class="gamification__form-row">
                <div class="gamification__form-field">
                  <label class="gamification__label">Минимальная сумма покупок (₸) *</label>
                  <v-text-field
                    v-model.number="form.min_purchase_amount"
                    type="number"
                    variant="outlined"
                    density="compact"
                    placeholder="100000"
                    rounded="lg"
                    :rules="[rules.required, rules.minZero]"
                  />
                </div>
                <div class="gamification__form-field gamification__form-field--color">
                  <label class="gamification__label">Цвет</label>
                  <div class="gamification__color-picker">
                    <input type="color" v-model="form.color" class="gamification__color-input" />
                    <v-text-field
                      v-model="form.color"
                      variant="outlined"
                      density="compact"
                      placeholder="#98B35D"
                      rounded="lg"
                      hide-details
                    />
                  </div>
                </div>
              </div>

              <div class="gamification__form-field">
                <v-switch
                  v-model="form.is_active"
                  label="Уровень активен"
                  color="success"
                  hide-details
                />
              </div>
            </div>

            <!-- Награды -->
            <div class="gamification__form-section">
              <div class="gamification__form-section-header">
                <p class="gamification__form-section-title">Награды за достижение уровня</p>
                <v-btn
                  variant="tonal"
                  color="primary"
                  size="small"
                  rounded="lg"
                  @click="addReward"
                >
                  <Icon name="mdi:plus" />
                  Добавить награду
                </v-btn>
              </div>

              <div v-if="form.rewards.length === 0" class="gamification__no-rewards-form">
                <Icon name="mdi:gift-off-outline" />
                <p>Добавьте награды, которые пользователь получит при достижении этого уровня</p>
              </div>

              <TransitionGroup name="reward-list" tag="div" class="gamification__rewards-form">
                <div
                  v-for="(reward, index) in form.rewards"
                  :key="reward._key || index"
                  class="gamification__reward-form"
                >
                  <div class="gamification__reward-form-header">
                    <span class="gamification__reward-form-number">Награда {{ index + 1 }}</span>
                    <v-btn
                      icon
                      variant="text"
                      size="x-small"
                      color="error"
                      @click="removeReward(index)"
                    >
                      <Icon name="mdi:close" />
                    </v-btn>
                  </div>

                  <div class="gamification__reward-form-content">
                    <div class="gamification__form-field">
                      <label class="gamification__label">Тип награды *</label>
                      <v-select
                        v-model="reward.reward_type"
                        :items="rewardTypes"
                        item-title="title"
                        item-value="value"
                        variant="outlined"
                        density="compact"
                        rounded="lg"
                        :rules="[rules.required]"
                        @update:model-value="onRewardTypeChange(reward)"
                      />
                    </div>

                    <!-- Поля для скидки -->
                    <div v-if="reward.reward_type === 'discount'" class="gamification__form-field">
                      <label class="gamification__label">Процент скидки *</label>
                      <v-select
                        v-model="reward.discount_percent"
                        :items="discountOptions"
                        item-title="title"
                        item-value="value"
                        variant="outlined"
                        density="compact"
                        rounded="lg"
                        :rules="[rules.required]"
                      />
                    </div>

                    <!-- Поля для бонусов -->
                    <div v-if="reward.reward_type === 'bonus'" class="gamification__form-field">
                      <label class="gamification__label">Сумма бонусов *</label>
                      <v-text-field
                        v-model.number="reward.bonus_amount"
                        type="number"
                        variant="outlined"
                        density="compact"
                        placeholder="5000"
                        suffix="₸"
                        rounded="lg"
                        :rules="[rules.required, rules.minZero]"
                      />
                    </div>

                    <!-- Выбор подарков -->
                    <div v-if="reward.reward_type === 'gift_choice'" class="gamification__form-field">
                      <label class="gamification__label">Подарки для выбора * (максимум 4)</label>
                      <v-select
                        v-model="reward.gift_ids"
                        :items="availableGifts"
                        item-title="name"
                        item-value="id"
                        multiple
                        chips
                        closable-chips
                        variant="outlined"
                        density="compact"
                        rounded="lg"
                        placeholder="Выберите подарки"
                        :rules="[rules.requiredArray, (v) => v.length <= 4 || 'Максимум 4 подарка']"
                        @update:model-value="limitGiftSelection(reward, $event)"
                      >
                        <template v-slot:chip="{ props, item }">
                          <v-chip
                            v-bind="props"
                            :prepend-avatar="item.raw.image_url"
                          >
                            {{ item.raw.name }}
                          </v-chip>
                        </template>
                        <template v-slot:item="{ props, item }">
                          <v-list-item v-bind="props">
                            <template v-slot:prepend>
                              <v-avatar size="32">
                                <v-img v-if="item.raw.image_url" :src="item.raw.image_url" />
                                <Icon v-else name="mdi:gift" />
                              </v-avatar>
                            </template>
                          </v-list-item>
                        </template>
                      </v-select>
                    </div>

                    <!-- Описание награды -->
                    <div class="gamification__form-field">
                      <label class="gamification__label">Описание (необязательно)</label>
                      <v-text-field
                        v-model="reward.description"
                        variant="outlined"
                        density="compact"
                        placeholder="Краткое описание награды"
                        rounded="lg"
                        hide-details
                      />
                    </div>
                  </div>
                </div>
              </TransitionGroup>
            </div>
          </v-form>
        </v-card-text>

        <v-card-actions class="gamification__dialog-actions">
          <v-btn variant="text" @click="closeDialog">Отмена</v-btn>
          <v-btn
            color="primary"
            variant="flat"
            :loading="saving"
            :disabled="saving"
            @click="saveLevel"
          >
            {{ editingLevel ? 'Сохранить' : 'Создать' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Диалог подтверждения удаления -->
    <v-dialog v-model="showDeleteDialog" max-width="400">
      <v-card rounded="xl">
        <v-card-title class="gamification__delete-title">
          <Icon name="mdi:alert-circle" class="gamification__delete-icon" />
          Удалить уровень?
        </v-card-title>
        <v-card-text>
          Вы уверены, что хотите удалить уровень "{{ levelToDelete?.name }}"?
          Это действие нельзя отменить.
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="showDeleteDialog = false">Отмена</v-btn>
          <v-btn color="error" variant="flat" :loading="deleting" @click="deleteLevel">
            Удалить
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const loading = ref(true);
const saving = ref(false);
const deleting = ref(false);
const levels = ref<Api.LoyaltyLevel.Self[]>([]);
const availableGifts = ref<Api.GiftCatalog.Self[]>([]);
const showDialog = ref(false);
const showDeleteDialog = ref(false);
const editingLevel = ref<Api.LoyaltyLevel.Self | null>(null);
const levelToDelete = ref<Api.LoyaltyLevel.Self | null>(null);
const formRef = ref();

// Ключ для отслеживания наград в списке
let rewardKeyCounter = 0;

// Доступные эмодзи для иконок уровней
const availableEmojis = [
  '🏆', '👑', '💎', '⭐', '🌟', '✨', '🎖️', '🥇', '🥈', '🥉',
  '🎯', '🚀', '💪', '🔥', '⚡', '🎁', '🎨', '🎭', '🎪', '🎸',
  '🎯', '🏅', '🎗️', '💫', '🌠', '🌌', '🌈', '🦄', '🐉', '👻',
  '🤖', '🎮', '💻', '📱', '⚙️', '🔧', '🛠️', '⚒️', '🔨', '🏗️',
];

// Состояние для popup иконок
const showEmojiPicker = ref(false);
const emojiPickerRef = ref();

const form = ref<{
  name: string;
  icon: string;
  color: string;
  min_purchase_amount: number;
  is_active: boolean;
  rewards: (Api.LoyaltyLevel.Reward & { _key?: number })[];
}>({
  name: '',
  icon: '🏆',
  color: '#98B35D',
  min_purchase_amount: 0,
  is_active: true,
  rewards: [],
});

const rewardTypes = [
  { value: 'discount', title: '💎 Персональная скидка' },
  { value: 'bonus', title: '⭐ Начисление бонусов' },
  { value: 'gift_choice', title: '🎁 Выбор подарка' },
];

// Фиксированные значения скидок, соответствующие профилю пользователя
const discountOptions = [
  { value: 0, title: 'Без скидки (0%)' },
  { value: 5, title: 'Дисконтная карта 5%' },
  { value: 10, title: 'Дисконтная карта 10%' },
  { value: 15, title: 'Дисконтная карта 15%' },
  { value: 20, title: 'Дисконтная карта 20%' },
  { value: 25, title: 'Дисконтная карта 25%' },
  { value: 30, title: 'Дисконтная карта 30%' },
  { value: 50, title: 'Корпоративный клиент 50%' },
  { value: 70, title: 'VIP карта 70%' },
];

const rules = {
  required: (v: any) => !!v || v === 0 || 'Обязательное поле',
  requiredArray: (v: any[]) => (v && v.length > 0) || 'Выберите хотя бы один вариант',
  minZero: (v: number) => v >= 0 || 'Значение должно быть >= 0',
  maxHundred: (v: number) => v <= 100 || 'Максимум 100%',
};

const sortedLevels = computed(() => {
  return [...levels.value].sort((a, b) => a.min_purchase_amount - b.min_purchase_amount);
});

// Загрузка данных
const loadLevels = async () => {
  loading.value = true;
  try {
    const response = await api.gamification.getAll();
    levels.value = Array.isArray(response) ? response : (response as any).data || [];
  } catch (err) {
    console.error('Ошибка загрузки уровней:', err);
    showToaster('error', 'Ошибка загрузки уровней');
  } finally {
    loading.value = false;
  }
};

const loadGifts = async () => {
  try {
    const response = await api.gamification.getGifts();
    availableGifts.value = Array.isArray(response) ? response : (response as any).data || [];
  } catch (err) {
    console.error('Ошибка загрузки подарков:', err);
  }
};

// Форматирование числа
const formatNumber = (num: number) => {
  return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
};

// Получение иконки типа награды
const getRewardIcon = (type: Api.LoyaltyLevel.RewardType) => {
  switch (type) {
    case 'discount': return 'mdi:percent';
    case 'bonus': return 'mdi:star';
    case 'gift_choice': return 'mdi:gift';
    default: return 'mdi:gift';
  }
};

// Получение названия типа награды
const getRewardTypeName = (type: Api.LoyaltyLevel.RewardType) => {
  switch (type) {
    case 'discount': return 'Скидка';
    case 'bonus': return 'Бонусы';
    case 'gift_choice': return 'Подарок';
    default: return 'Награда';
  }
};

// Получение значения награды
const getRewardValue = (reward: Api.LoyaltyLevel.Reward) => {
  switch (reward.reward_type) {
    case 'discount':
      return `${reward.discount_percent}%`;
    case 'bonus':
      return `${formatNumber(reward.bonus_amount || 0)} ₸`;
    case 'gift_choice':
      const count = reward.gift_options?.length || reward.gift_ids?.length || 0;
      return `${count} вариант${count === 1 ? '' : count < 5 ? 'а' : 'ов'}`;
    default:
      return reward.description || '';
  }
};

// Открыть диалог создания
const openCreateDialog = () => {
  editingLevel.value = null;
  form.value = {
    name: '',
    icon: '🏆',
    color: '#98B35D',
    min_purchase_amount: 0,
    is_active: true,
    rewards: [],
  };
  showDialog.value = true;
};

// Редактировать уровень
const editLevel = (level: Api.LoyaltyLevel.Self) => {
  editingLevel.value = level;
  form.value = {
    name: level.name,
    icon: level.icon || '🏆',
    color: level.color || '#98B35D',
    min_purchase_amount: level.min_purchase_amount,
    is_active: level.is_active,
    rewards: level.rewards.map(r => ({
      ...r,
      _key: ++rewardKeyCounter,
      gift_ids: r.gift_options?.map(g => g.id) || r.gift_ids || [],
    })),
  };
  showDialog.value = true;
};

// Закрыть диалог
const closeDialog = () => {
  showDialog.value = false;
  editingLevel.value = null;
};

// Добавить награду
const addReward = () => {
  form.value.rewards.push({
    _key: ++rewardKeyCounter,
    reward_type: 'bonus',
    discount_percent: null,
    bonus_amount: 1000,
    description: null,
    is_active: true,
    gift_ids: [],
  });
};

// Удалить награду
const removeReward = (index: number) => {
  form.value.rewards.splice(index, 1);
};

// Изменение типа награды
const onRewardTypeChange = (reward: Api.LoyaltyLevel.Reward & { _key?: number }) => {
  reward.discount_percent = null;
  reward.bonus_amount = null;
  reward.gift_ids = [];
  
  if (reward.reward_type === 'discount') {
    reward.discount_percent = 10;
  } else if (reward.reward_type === 'bonus') {
    reward.bonus_amount = 1000;
  }
};

// Ограничение выбора подарков максимум 4 штуками
const limitGiftSelection = (reward: Api.LoyaltyLevel.Reward & { _key?: number }, newValue: number[]) => {
  if (newValue.length > 4) {
    reward.gift_ids = newValue.slice(0, 4);
  } else {
    reward.gift_ids = newValue;
  }
};

// Сохранить уровень
const saveLevel = async () => {
  const { valid } = await formRef.value.validate();
  if (!valid) return;

  saving.value = true;
  try {
    const payload: Api.LoyaltyLevel.New = {
      name: form.value.name,
      icon: form.value.icon,
      color: form.value.color,
      min_purchase_amount: form.value.min_purchase_amount,
      is_active: form.value.is_active,
      rewards: form.value.rewards.map(r => ({
        id: r.id,
        reward_type: r.reward_type,
        discount_percent: r.discount_percent,
        bonus_amount: r.bonus_amount,
        description: r.description,
        is_active: r.is_active,
        gift_ids: r.gift_ids,
      })),
    };

    if (editingLevel.value) {
      await api.gamification.update(editingLevel.value.id, payload);
      showToaster('success', 'Уровень обновлён');
    } else {
      await api.gamification.add(payload);
      showToaster('success', 'Уровень создан');
    }

    closeDialog();
    await loadLevels();
  } catch (err: any) {
    console.error('Ошибка сохранения:', err);
    showToaster('error', err?.response?.data?.message || 'Ошибка сохранения');
  } finally {
    saving.value = false;
  }
};

// Подтверждение удаления
const confirmDelete = (level: Api.LoyaltyLevel.Self) => {
  levelToDelete.value = level;
  showDeleteDialog.value = true;
};

// Удаление уровня
const deleteLevel = async () => {
  if (!levelToDelete.value) return;

  deleting.value = true;
  try {
    await api.gamification.delete(levelToDelete.value.id);
    showToaster('success', 'Уровень удалён');
    showDeleteDialog.value = false;
    levelToDelete.value = null;
    await loadLevels();
  } catch (err: any) {
    console.error('Ошибка удаления:', err);
    showToaster('error', err?.response?.data?.message || 'Ошибка удаления');
  } finally {
    deleting.value = false;
  }
};

onMounted(async () => {
  await Promise.all([loadLevels(), loadGifts()]);
});
</script>

<style scoped>
.gamification {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

/* Header */
.gamification__header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
  flex-wrap: wrap;
}

.gamification__title-section {
  flex: 1;
  min-width: 200px;
}

.gamification__title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-text-primary);
  margin: 0;
}

.gamification__title-icon {
  font-size: 1.75rem;
  color: var(--color-accent);
}

.gamification__subtitle {
  margin-top: 0.25rem;
  font-size: 0.875rem;
  color: var(--color-text-secondary);
}

.gamification__add-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.gamification__add-icon {
  font-size: 1.25rem;
}

/* Loading */
.gamification__loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  min-height: 300px;
  color: var(--color-text-secondary);
}

/* Empty state */
.gamification__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 3rem 2rem;
  background: var(--color-bg-card);
  border-radius: 1.5rem;
  text-align: center;
}

.gamification__empty-icon {
  font-size: 4rem;
  color: var(--color-text-muted);
  opacity: 0.5;
}

.gamification__empty-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--color-text-primary);
  margin: 0;
}

.gamification__empty-text {
  font-size: 0.875rem;
  color: var(--color-text-secondary);
  max-width: 400px;
}

/* Levels grid */
.gamification__levels-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 1.25rem;
}

/* Level card */
.gamification__level {
  display: flex;
  flex-direction: column;
  background: var(--color-bg-card);
  border-radius: 1rem;
  overflow: hidden;
  box-shadow: 0 2px 8px var(--color-shadow);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  border-left: 4px solid var(--level-color, var(--color-accent));
}

.gamification__level:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px var(--color-shadow);
}

/* Level header */
.gamification__level-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem 1.25rem;
  background: linear-gradient(135deg, rgba(var(--color-accent-rgb), 0.05) 0%, transparent 100%);
  border-bottom: 1px solid var(--color-border);
}

.gamification__level-badge {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--level-color) 0%, color-mix(in srgb, var(--level-color) 70%, black) 100%);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.gamification__level-icon {
  font-size: 1.75rem;
}

.gamification__level-order {
  position: absolute;
  bottom: -4px;
  right: -4px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 22px;
  height: 22px;
  font-size: 0.625rem;
  font-weight: 700;
  color: white;
  background: var(--color-bg-tertiary);
  border-radius: 50%;
  border: 2px solid var(--color-bg-card);
  color: var(--color-text-primary);
}

.gamification__level-info {
  flex: 1;
  min-width: 0;
}

.gamification__level-name {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text-primary);
  margin: 0;
}

.gamification__level-threshold {
  font-size: 0.8rem;
  color: var(--color-text-secondary);
  margin: 0.25rem 0 0;
}

.gamification__level-actions {
  display: flex;
  gap: 0.25rem;
}

/* Level rewards */
.gamification__level-rewards {
  flex: 1;
  padding: 1rem 1.25rem;
}

.gamification__rewards-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin: 0 0 0.75rem;
}

.gamification__rewards-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.gamification__reward {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.625rem 0.875rem;
  border-radius: 0.625rem;
  background: var(--color-bg-tertiary);
}

.gamification__reward--discount {
  background: linear-gradient(135deg, rgba(33, 150, 243, 0.1) 0%, rgba(33, 150, 243, 0.05) 100%);
}

.gamification__reward--discount .gamification__reward-icon {
  color: #2196F3;
  background: rgba(33, 150, 243, 0.15);
}

.gamification__reward--bonus {
  background: linear-gradient(135deg, rgba(255, 193, 7, 0.1) 0%, rgba(255, 193, 7, 0.05) 100%);
}

.gamification__reward--bonus .gamification__reward-icon {
  color: #FFC107;
  background: rgba(255, 193, 7, 0.15);
}

.gamification__reward--gift_choice {
  background: linear-gradient(135deg, rgba(233, 30, 99, 0.1) 0%, rgba(233, 30, 99, 0.05) 100%);
}

.gamification__reward--gift_choice .gamification__reward-icon {
  color: #E91E63;
  background: rgba(233, 30, 99, 0.15);
}

.gamification__reward-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  font-size: 1rem;
}

.gamification__reward-content {
  display: flex;
  flex-direction: column;
  gap: 0.125rem;
}

.gamification__reward-type {
  font-size: 0.7rem;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.gamification__reward-value {
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.gamification__no-rewards {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.8rem;
  color: var(--color-text-muted);
  margin: 0;
}

/* Level footer */
.gamification__level-footer {
  margin-top: auto;
  padding: 0.75rem 1.25rem;
  border-top: 1px solid var(--color-border);
}

/* Dialog */
.gamification__dialog {
  max-height: 90vh;
}

.gamification__dialog-title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 1.25rem;
  font-weight: 600;
  padding: 1.25rem 1.5rem;
  border-bottom: 1px solid var(--color-border);
}

.gamification__dialog-icon {
  font-size: 1.5rem;
  color: var(--color-accent);
}

.gamification__dialog-content {
  padding: 1.5rem !important;
  overflow-y: auto;
}

.gamification__dialog-actions {
  padding: 1rem 1.5rem;
  border-top: 1px solid var(--color-border);
  justify-content: flex-end;
  gap: 0.5rem;
}

/* Form */
.gamification__form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.gamification__form-section {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.gamification__form-section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
}

.gamification__form-section-title {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text-secondary);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin: 0;
}

.gamification__form-row {
  display: flex;
  gap: 1rem;
}

.gamification__form-field {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
}

.gamification__form-field--icon {
  flex: 0 0 80px;
}

.gamification__form-field--name {
  flex: 1;
}

.gamification__form-field--color {
  flex: 0 0 160px;
}

.gamification__label {
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--color-text-secondary);
}

.gamification__color-picker {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.gamification__color-input {
  width: 40px;
  height: 40px;
  padding: 0;
  border: none;
  border-radius: 0.5rem;
  cursor: pointer;
  background: transparent;
}

.gamification__color-input::-webkit-color-swatch-wrapper {
  padding: 0;
}

.gamification__color-input::-webkit-color-swatch {
  border: 2px solid var(--color-border);
  border-radius: 0.5rem;
}

.gamification__input--icon :deep(.v-field__input) {
  text-align: center;
  font-size: 1.5rem;
}

/* Rewards form */
.gamification__no-rewards-form {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  padding: 2rem;
  background: var(--color-bg-tertiary);
  border-radius: 0.75rem;
  text-align: center;
  color: var(--color-text-muted);
}

.gamification__no-rewards-form .iconify {
  font-size: 2rem;
  opacity: 0.5;
}

.gamification__rewards-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.gamification__reward-form {
  background: var(--color-bg-tertiary);
  border-radius: 0.875rem;
  overflow: hidden;
}

.gamification__reward-form-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1rem;
  background: var(--color-bg-secondary);
  border-bottom: 1px solid var(--color-border);
}

.gamification__reward-form-number {
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--color-text-secondary);
}

.gamification__reward-form-content {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  padding: 1rem;
}

/* Delete dialog */
.gamification__delete-title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  color: var(--color-text-primary);
}

.gamification__delete-icon {
  font-size: 1.5rem;
  color: #f44336;
}

/* Emoji Picker */
.gamification__emoji-picker {
  background: var(--color-bg-card);
  border-radius: 0.75rem;
  padding: 1rem;
  box-shadow: 0 8px 24px var(--color-shadow);
  min-width: 300px;
}

.gamification__emoji-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(40px, 1fr));
  gap: 0.5rem;
}

.gamification__emoji-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  font-size: 1.5rem;
  background: var(--color-bg-tertiary);
  border: 2px solid var(--color-border);
  border-radius: 0.5rem;
  cursor: pointer;
  transition: all 0.2s ease;
  padding: 0;
}

.gamification__emoji-btn:hover {
  background: var(--color-accent);
  border-color: var(--color-accent);
  transform: scale(1.1);
}

.gamification__emoji-btn--selected {
  background: var(--color-accent);
  border-color: var(--color-accent);
  box-shadow: 0 0 8px var(--color-accent);
}

/* Animations */
.level-list-enter-active,
.level-list-leave-active {
  transition: all 0.3s ease;
}

.level-list-enter-from,
.level-list-leave-to {
  opacity: 0;
  transform: translateY(20px);
}

.reward-list-enter-active,
.reward-list-leave-active {
  transition: all 0.25s ease;
}

.reward-list-enter-from,
.reward-list-leave-to {
  opacity: 0;
  transform: translateX(-10px);
}

/* Responsive */
@media (max-width: 768px) {
  .gamification__header {
    flex-direction: column;
    align-items: stretch;
  }

  .gamification__add-btn {
    width: 100%;
  }

  .gamification__levels-grid {
    grid-template-columns: 1fr;
  }

  .gamification__form-row {
    flex-direction: column;
  }

  .gamification__form-field--icon,
  .gamification__form-field--color {
    flex: auto;
  }
}
</style>




