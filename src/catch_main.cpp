#define CATCH_CONFIG_MAIN
#include "catch.hpp"

#include "mock_interface.hpp"
#include "reporter_interface.hpp"

struct MockListener : Catch::TestEventListenerBase {

    using TestEventListenerBase::TestEventListenerBase; // inherit constructor

    virtual void testCaseStarting( Catch::TestCaseInfo const& testInfo ) override {
        init_mocks();
    }
    
    virtual void testCaseEnded( Catch::TestCaseStats const& testCaseStats ) override {
        destroy_mocks();
        pass_reports();
    }    
};

CATCH_REGISTER_LISTENER( MockListener )