all:
	$(MAKE) -C debug all
	$(MAKE) -C assert all
	$(MAKE) -C relwithdebinfo all
	$(MAKE) -C release all
	
clean:
	$(MAKE) -C debug clean
	$(MAKE) -C assert clean
	$(MAKE) -C relwithdebinfo clean
	$(MAKE) -C release clean

distclean:
	rm -rf debug
	rm -rf assert
	rm -rf relwithdebinfo
	rm -rf release
	