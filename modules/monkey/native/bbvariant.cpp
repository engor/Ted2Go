
#include "bbvariant.h"

bbVariant::RepBase bbVariant::_null;

template struct bbVariant::Rep<bbBool>;
template struct bbVariant::Rep<bbByte>;
template struct bbVariant::Rep<bbUByte>;
template struct bbVariant::Rep<bbShort>;
template struct bbVariant::Rep<bbUShort>;
template struct bbVariant::Rep<bbInt>;
template struct bbVariant::Rep<bbUInt>;
template struct bbVariant::Rep<bbLong>;
template struct bbVariant::Rep<bbULong>;
template struct bbVariant::Rep<bbFloat>;
template struct bbVariant::Rep<bbDouble>;
template struct bbVariant::Rep<bbString>;

