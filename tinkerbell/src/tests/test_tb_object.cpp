// ================================================================================
// == This file is a part of TinkerBell UI Toolkit. (C) 2011-2013, Emil Seger�s  ==
// ==                   See tinkerbell.h for more information.                   ==
// ================================================================================

#include "tb_test.h"
#include "tb_object.h"

#ifdef TB_UNIT_TESTING

using namespace tinkerbell;

TB_TEST_GROUP(tb_object)
{
	class Car : public TBTypedObject
	{
	public:
		TBOBJECT_SUBCLASS(Car, TBTypedObject);
	};

	class Fruit : public TBTypedObject
	{
	public:
		TBOBJECT_SUBCLASS(Fruit, TBTypedObject);
	};

	class Apple : public Fruit
	{
	public:
		TBOBJECT_SUBCLASS(Apple, Fruit);
	};

	TB_TEST(safe_cast)
	{
		Fruit *fruit = new Fruit();
		Apple *apple = new Apple();
		Car *car = new Car();

		TB_VERIFY(TBSafeCast<TBTypedObject>(fruit));
		TB_VERIFY(TBSafeCast<TBTypedObject>(apple));
		TB_VERIFY(TBSafeCast<TBTypedObject>(car));

		TB_VERIFY(TBSafeCast<Fruit>(fruit));
		TB_VERIFY(TBSafeCast<Fruit>(apple));
		TB_VERIFY(!TBSafeCast<Fruit>(car));

		TB_VERIFY(!TBSafeCast<Apple>(fruit));
		TB_VERIFY(TBSafeCast<Apple>(apple));
		TB_VERIFY(!TBSafeCast<Apple>(car));

		TB_VERIFY(!TBSafeCast<Car>(fruit));
		TB_VERIFY(!TBSafeCast<Car>(apple));
		TB_VERIFY(TBSafeCast<Car>(car));
	}
}

#endif // TB_UNIT_TESTING