/**
 * 播放列表管理服务
 * 负责播放列表的增删改查，使用 Preferences 进行本地持久化存储
 *
 * 技术要点：
 * - 使用 @ohos.data.preferences 持久化存储
 * - 存储键名：'playlists'
 * - 最大项目数：500
 * - 自动更新 totalCount 和 totalDuration
 */

import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { Playlist } from '../models/Playlist';
import { PlaylistItem } from '../models/PlaylistItem';
import { PlaylistErrorCode, createError, MusicPlayerError } from '../common/ErrorCodes';
import { MAX_PLAYLIST_ITEMS } from '../common/Constants';
import { generateId } from '../common/Utils';

/**
 * 创建播放列表错误对象
 * @param errorCode 错误码
 * @returns Error 对象
 */
function createPlaylistError(errorCode: PlaylistErrorCode): Error {
  const errorInfo: MusicPlayerError = createError(errorCode);
  return new Error(`[${errorInfo.code}] ${errorInfo.message}`);
}

/**
 * 播放列表名称最大长度
 */
const MAX_PLAYLIST_NAME_LENGTH: number = 50;

/**
 * Preferences 存储文件名
 */
const PREFERENCES_NAME: string = 'music_player_data';

/**
 * 播放列表存储键名
 */
const PLAYLISTS_STORAGE_KEY: string = 'playlists';

/**
 * 播放列表服务类
 * 实现播放列表的完整生命周期管理
 */
export class PlaylistService {
  /** Preferences 实例 */
  private preferencesInstance: preferences.Preferences | null = null;

  /** 应用上下文 */
  private context: common.UIAbilityContext;

  /** 初始化标志 */
  private initialized: boolean = false;

  /**
   * 构造函数
   * @param context 应用上下文
   */
  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  /**
   * 初始化 Preferences 实例
   * 必须在使用其他方法前调用
   */
  private async initPreferences(): Promise<void> {
    if (this.initialized && this.preferencesInstance !== null) {
      return;
    }

    try {
      this.preferencesInstance = await preferences.getPreferences(this.context, PREFERENCES_NAME);
      this.initialized = true;
    } catch (error) {
      const err = error as Error;
      console.error('[PlaylistService] 初始化 Preferences 失败:', err.message);
      throw new Error(`初始化 Preferences 失败: ${err.message}`);
    }
  }

  /**
   * 获取所有播放列表
   * @returns 播放列表数组
   */
  async getAll(): Promise<Playlist[]> {
    await this.initPreferences();

    try {
      const data: preferences.ValueType | undefined =
        await this.preferencesInstance!.get(PLAYLISTS_STORAGE_KEY, '[]');
      const playlistsJson: string = data as string;
      const playlists: Playlist[] = JSON.parse(playlistsJson) as Playlist[];
      return playlists;
    } catch (error) {
      console.error('[PlaylistService] 获取播放列表失败:', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 根据 ID 获取播放列表
   * @param id 播放列表 ID
   * @returns 播放列表对象，不存在则返回 null
   */
  async getById(id: string): Promise<Playlist | null> {
    const playlists: Playlist[] = await this.getAll();
    const playlist: Playlist | undefined = playlists.find((p: Playlist): boolean => p.id === id);
    return playlist !== undefined ? playlist : null;
  }

  /**
   * 创建新播放列表
   * @param name 播放列表名称
   * @returns 新创建的播放列表
   * @throws PLAYLIST_NAME_EMPTY - 名称为空
   * @throws PLAYLIST_NAME_TOO_LONG - 名称过长
   */
  async create(name: string): Promise<Playlist> {
    // 验证名称
    const trimmedName: string = name.trim();
    if (trimmedName.length === 0) {
      const errorInfo = createError(PlaylistErrorCode.PLAYLIST_NAME_EMPTY);
      throw new Error(`[${errorInfo.code}] ${errorInfo.message}`);
    }
    if (trimmedName.length > MAX_PLAYLIST_NAME_LENGTH) {
      const errorInfo = createError(PlaylistErrorCode.PLAYLIST_NAME_TOO_LONG);
      throw new Error(`[${errorInfo.code}] ${errorInfo.message}`);
    }

    const now: number = Date.now();
    const newPlaylist: Playlist = {
      id: generateId('playlist'),
      name: trimmedName,
      items: [],
      totalCount: 0,
      totalDuration: 0,
      createdAt: now,
      updatedAt: now,
      isSystem: false
    };

    const playlists: Playlist[] = await this.getAll();
    playlists.push(newPlaylist);
    await this.savePlaylists(playlists);

    console.info('[PlaylistService] 创建播放列表成功:', newPlaylist.id);
    return newPlaylist;
  }

  /**
   * 更新播放列表
   * @param id 播放列表 ID
   * @param data 要更新的数据
   * @throws PLAYLIST_NOT_FOUND - 列表不存在
   * @throws PLAYLIST_NAME_EMPTY - 名称为空
   * @throws PLAYLIST_NAME_TOO_LONG - 名称过长
   */
  async update(id: string, data: Partial<Playlist>): Promise<void> {
    // 验证名称（如果提供）
    if (data.name !== undefined) {
      const trimmedName: string = data.name.trim();
      if (trimmedName.length === 0) {
        throw createPlaylistError(PlaylistErrorCode.PLAYLIST_NAME_EMPTY);
      }
      if (trimmedName.length > MAX_PLAYLIST_NAME_LENGTH) {
        throw createPlaylistError(PlaylistErrorCode.PLAYLIST_NAME_TOO_LONG);
      }
      data.name = trimmedName;
    }

    const playlists: Playlist[] = await this.getAll();
    const index: number = playlists.findIndex((p: Playlist): boolean => p.id === id);

    if (index === -1) {
      throw createPlaylistError(PlaylistErrorCode.PLAYLIST_NOT_FOUND);
    }

    // 合并更新数据（不更新 id、isSystem、createdAt）
    const original: Playlist = playlists[index];
    const updatedPlaylist: Playlist = {
      id: original.id,
      name: data.name !== undefined ? data.name : original.name,
      items: data.items !== undefined ? data.items : original.items,
      totalCount: data.totalCount !== undefined ? data.totalCount : original.totalCount,
      totalDuration: data.totalDuration !== undefined ? data.totalDuration : original.totalDuration,
      createdAt: original.createdAt,
      updatedAt: Date.now(),
      isSystem: original.isSystem
    };

    playlists[index] = updatedPlaylist;
    await this.savePlaylists(playlists);

    console.info('[PlaylistService] 更新播放列表成功:', id);
  }

  /**
   * 删除播放列表
   * @param id 播放列表 ID
   * @throws PLAYLIST_NOT_FOUND - 列表不存在
   * @throws PLAYLIST_IS_SYSTEM - 系统列表不可删除
   */
  async delete(id: string): Promise<void> {
    const playlists: Playlist[] = await this.getAll();
    const index: number = playlists.findIndex((p: Playlist): boolean => p.id === id);

    if (index === -1) {
      throw createPlaylistError(PlaylistErrorCode.PLAYLIST_NOT_FOUND);
    }

    if (playlists[index].isSystem) {
      throw createPlaylistError(PlaylistErrorCode.PLAYLIST_IS_SYSTEM);
    }

    playlists.splice(index, 1);
    await this.savePlaylists(playlists);

    console.info('[PlaylistService] 删除播放列表成功:', id);
  }

  /**
   * 添加项目到播放列表
   * @param playlistId 播放列表 ID
   * @param item 要添加的项目
   * @throws PLAYLIST_NOT_FOUND - 列表不存在
   * @throws PLAYLIST_FULL - 列表已满（500 项）
   * @throws PLAYLIST_DUPLICATE - 项目已存在
   */
  async addItem(playlistId: string, item: PlaylistItem): Promise<void> {
    const playlists: Playlist[] = await this.getAll();
    const index: number = playlists.findIndex((p: Playlist): boolean => p.id === playlistId);

    if (index === -1) {
      throw createPlaylistError(PlaylistErrorCode.PLAYLIST_NOT_FOUND);
    }

    const playlist: Playlist = playlists[index];

    // 检查数量限制
    if (playlist.items.length >= MAX_PLAYLIST_ITEMS) {
      throw createPlaylistError(PlaylistErrorCode.PLAYLIST_FULL);
    }

    // 检查重复
    const exists: boolean = playlist.items.some(
      (existingItem: PlaylistItem): boolean => existingItem.trackId === item.trackId
    );
    if (exists) {
      throw createPlaylistError(PlaylistErrorCode.PLAYLIST_DUPLICATE);
    }

    // 设置项目顺序
    item.order = playlist.items.length;
    item.addedAt = Date.now();

    // 添加项目
    playlist.items.push(item);

    // 更新统计信息
    this.updatePlaylistStats(playlist);
    playlist.updatedAt = Date.now();

    playlists[index] = playlist;
    await this.savePlaylists(playlists);

    console.info('[PlaylistService] 添加项目成功:', item.id, '到播放列表:', playlistId);
  }

  /**
   * 从播放列表移除项目
   * @param playlistId 播放列表 ID
   * @param itemId 项目 ID
   * @throws PLAYLIST_NOT_FOUND - 列表不存在
   */
  async removeItem(playlistId: string, itemId: string): Promise<void> {
    const playlists: Playlist[] = await this.getAll();
    const playlistIndex: number = playlists.findIndex(
      (p: Playlist): boolean => p.id === playlistId
    );

    if (playlistIndex === -1) {
      throw createPlaylistError(PlaylistErrorCode.PLAYLIST_NOT_FOUND);
    }

    const playlist: Playlist = playlists[playlistIndex];
    const itemIndex: number = playlist.items.findIndex(
      (item: PlaylistItem): boolean => item.id === itemId
    );

    if (itemIndex === -1) {
      // 项目不存在，静默返回
      console.warn('[PlaylistService] 项目不存在:', itemId);
      return;
    }

    // 移除项目
    playlist.items.splice(itemIndex, 1);

    // 重新排序剩余项目
    for (let i: number = 0; i < playlist.items.length; i++) {
      playlist.items[i].order = i;
    }

    // 更新统计信息
    this.updatePlaylistStats(playlist);
    playlist.updatedAt = Date.now();

    playlists[playlistIndex] = playlist;
    await this.savePlaylists(playlists);

    console.info('[PlaylistService] 移除项目成功:', itemId, '从播放列表:', playlistId);
  }

  /**
   * 保存播放列表到 Preferences
   * @param playlists 播放列表数组
   */
  private async savePlaylists(playlists: Playlist[]): Promise<void> {
    await this.initPreferences();

    try {
      const playlistsJson: string = JSON.stringify(playlists);
      await this.preferencesInstance!.put(PLAYLISTS_STORAGE_KEY, playlistsJson);
      await this.preferencesInstance!.flush();
    } catch (error) {
      const err = error as Error;
      console.error('[PlaylistService] 保存播放列表失败:', err.message);
      throw new Error(`保存播放列表失败: ${err.message}`);
    }
  }

  /**
   * 更新播放列表统计信息
   * 自动计算 totalCount
   * 注意：totalDuration 需要外部提供实际时长信息，此处保持为 0
   * @param playlist 播放列表对象
   */
  private updatePlaylistStats(playlist: Playlist): void {
    playlist.totalCount = playlist.items.length;
    // totalDuration 的计算需要实际的音频时长信息
    // 由于 PlaylistItem 不包含 duration 字段，这里保持为 0
    // 如需计算，需要额外查询关联的 MusicTrack 或 RadioStation
    playlist.totalDuration = 0;
  }

  /**
   * 检查播放列表是否存在
   * @param id 播放列表 ID
   * @returns 是否存在
   */
  async exists(id: string): Promise<boolean> {
    const playlist: Playlist | null = await this.getById(id);
    return playlist !== null;
  }

  /**
   * 获取播放列表中的项目数量
   * @param id 播放列表 ID
   * @returns 项目数量，不存在返回 -1
   */
  async getItemCount(id: string): Promise<number> {
    const playlist: Playlist | null = await this.getById(id);
    return playlist !== null ? playlist.totalCount : -1;
  }

  /**
   * 清空播放列表中的所有项目（不删除列表本身）
   * @param id 播放列表 ID
   * @throws PLAYLIST_NOT_FOUND - 列表不存在
   */
  async clearItems(id: string): Promise<void> {
    const playlists: Playlist[] = await this.getAll();
    const index: number = playlists.findIndex((p: Playlist): boolean => p.id === id);

    if (index === -1) {
      throw createPlaylistError(PlaylistErrorCode.PLAYLIST_NOT_FOUND);
    }

    playlists[index].items = [];
    playlists[index].totalCount = 0;
    playlists[index].totalDuration = 0;
    playlists[index].updatedAt = Date.now();

    await this.savePlaylists(playlists);

    console.info('[PlaylistService] 清空播放列表项目成功:', id);
  }
}

/**
 * 创建播放列表服务实例
 * @param context 应用上下文
 * @returns PlaylistService 实例
 */
export function createPlaylistService(context: common.UIAbilityContext): PlaylistService {
  return new PlaylistService(context);
}
