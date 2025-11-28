import { format, isValid } from 'date-fns';

export const formatToYYYYMMDD = (dateString: string | null): string => {
  if (!dateString) {
    return '';
  }

  const date = new Date(dateString);
  if (!isValid(date)) {
    return '';
  }

  return format(date, 'yyyy-MM-dd');
};
