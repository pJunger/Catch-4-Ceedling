#define CATCH_CONFIG_RUNNER
#define CATCH_CONFIG_FAST_COMPILE
#include "catch.hpp"

#include "mock_interface.h"
/* #include "reporter_interface.h" */

struct MockListener : Catch::TestEventListenerBase {

    using TestEventListenerBase::TestEventListenerBase; // inherit constructor

    virtual void testCaseStarting( Catch::TestCaseInfo const& testInfo ) override {
        init_mocks();
    }
    virtual void sectionStarting( Catch::SectionInfo const& sectionInfo ) {
        if (m_sectionStack.size() == 0) {
          init_mocks();
        }
        m_sectionStack.push_back( sectionInfo );
    }
    
    virtual void testCaseEnded( Catch::TestCaseStats const& testCaseStats ) override {
        destroy_mocks();
        /* pass_reports(); */
    }    
    virtual void sectionEnded( Catch::SectionStats const& sectionStats ) {
        m_sectionStack.pop_back();
        if (m_sectionStack.size() == 0) {
          destroy_mocks();
          /* pass_reports(); */
        }
    }

    
};


CATCH_REGISTER_LISTENER( MockListener )


int main( int argc, char* argv[] ) {
  
  int result;
  if (argc < 2) {
    /* Either no arguments, or it's just the name */
    
    /* Add xml reporter to call as that's what we are parsing later on */
    const char name[] = "test_runner";
    const char reporter[] = "-r";
    const char kind[] = "xml";

    const int argc_mod = 3;
    const char* argv_mod[argc_mod];
    argv_mod[0] = name;
    argv_mod[1] = reporter;
    argv_mod[2] = kind;

    result = Catch::Session().run( argc_mod, argv_mod );
  } else {
    /* We called the executable from outside Ceedling */
    result = Catch::Session().run( argc, argv );
  }

  return ( result < 0xff ? result : 0xff );
}
