
#ifndef EXTERNS_H
#define EXTERNS_H

namespace test{

	enum E{
		V1,
		V2
	};
	
	namespace E2{
		enum{
			V1,
			V2
		};
	}
	
	struct C{
	
		int P;
		
		static int G;
		
		static const int T=0;
		
		void M(){}
		
		static void F(){}
		
		static inline void Update(){}
		
		struct D{
		
			static inline void F(){}
		};
	};
	
	inline void C_M2( C *c,int x,int y ){}

}

#endif
